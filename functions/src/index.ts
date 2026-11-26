import { createHash } from "node:crypto";
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const reserved = new Set([
  "admin", "administrator", "support", "help", "moderator",
  "kakarot", "firebase", "google", "root", "system", "null",
  "undefined",
]);

function validateUsername(input: unknown): { original: string; lower: string } {
  if (typeof input !== "string") {
    throw new HttpsError("invalid-argument", "Invalid username.");
  }
  const original = input.trim();
  const lower = original.toLowerCase();
  if (lower.length < 3 || lower.length > 20) {
    throw new HttpsError("invalid-argument", "Username must be 3–20 characters.");
  }
  if (!/^[a-z0-9](?:[a-z0-9._]*[a-z0-9])$/.test(lower)) {
    throw new HttpsError("invalid-argument", "Use only letters, numbers, underscores, and periods.");
  }
  if (reserved.has(lower)) {
    throw new HttpsError("invalid-argument", "This username is not available.");
  }
  return { original, lower };
}

async function enforceRateLimit(uid: string, action: string, max: number, windowMs: number) {
  const ref = db.collection("rateLimits").doc(action + "_" + uid);
  const now = Date.now();
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const data = snapshot.data();
    const startedAt = typeof data?.window_started_at === "number" ? data.window_started_at : 0;
    const count = startedAt > 0 && now - startedAt < windowMs
      ? (typeof data?.count === "number" ? data.count : 0)
      : 0;
    if (count >= max) {
      throw new HttpsError("resource-exhausted", "Too many requests. Please try again later.");
    }
    transaction.set(ref, {
      count: count + 1,
      window_started_at: count === 0 ? now : startedAt,
      updated_at: FieldValue.serverTimestamp(),
    });
  });
}

export const checkUsername = onCall(
  { enforceAppCheck: true, maxInstances: 10 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
    await enforceRateLimit(uid, "username_check", 30, 60_000);
    const name = validateUsername(request.data?.username);
    const reservation = await db.collection("usernames").doc(name.lower).get();
    return { available: !reservation.exists || reservation.data()?.uid === uid };
  },
);

export const completeProfile = onCall(
  { enforceAppCheck: true, maxInstances: 10 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
    await enforceRateLimit(uid, "complete_profile", 5, 60 * 60_000);

    const name = validateUsername(request.data?.username);
    const displayName = typeof request.data?.displayName === "string"
      ? request.data.displayName.trim().slice(0, 40)
      : "";
    if (!displayName) throw new HttpsError("invalid-argument", "A display name is required.");

    const account = await getAuth().getUser(uid);
    const email = account.email?.trim().toLowerCase();
    if (!email) throw new HttpsError("failed-precondition", "An email address is required.");
    if (!account.providerData.some((provider) => provider.providerId === "password")) {
      throw new HttpsError("failed-precondition", "Link an email/password credential before completing the profile.");
    }

    const userRef = db.collection("users").doc(uid);
    const profileRef = db.collection("profiles").doc(uid);
    const usernameRef = db.collection("usernames").doc(name.lower);
    const mappingRef = db.collection("usernameAuth").doc(name.lower);
    const emailHash = createHash("sha256").update(email, "utf8").digest("hex");

    await db.runTransaction(async (transaction) => {
      const [reservation, mapping, existingUser] = await Promise.all([
        transaction.get(usernameRef),
        transaction.get(mappingRef),
        transaction.get(userRef),
      ]);

      if (reservation.exists && reservation.data()?.uid !== uid) {
        throw new HttpsError("already-exists", "Username already taken.");
      }
      if (mapping.exists && mapping.data()?.uid !== uid) {
        throw new HttpsError("already-exists", "Username already taken.");
      }

      const now = FieldValue.serverTimestamp();
      const photoURL = account.photoURL ?? "";
      const createdAt = existingUser.data()?.created_at ?? now;

      transaction.set(usernameRef, {
        uid,
        username: name.original,
        username_lower: name.lower,
        created_at: reservation.data()?.created_at ?? now,
      });

      // Private server-only mapping. Client rules must deny all access.
      transaction.set(mappingRef, {
        uid,
        email,
        username_lower: name.lower,
        created_at: mapping.data()?.created_at ?? now,
      });

      transaction.set(userRef, {
        uid,
        user_id: uid,
        username: name.original,
        username_lower: name.lower,
        displayName,
        email,
        photoURL,
        profile_photo: photoURL,
        hasPassword: true,
        created_at: createdAt,
        updated_at: now,
      }, { merge: true });

      // Preserve legacy field names for the existing JavaScript chat client.
      transaction.set(profileRef, {
        user_id: uid,
        username: name.original,
        username_lower: name.lower,
        profile_photo: photoURL,
        email_hash: emailHash,
        status: "online",
        last_active_at: now,
      }, { merge: true });
    });

    return { success: true };
  },
);


// Backfill the public directory record for accounts created by the legacy app.
// A missing profiles/{uid} document is not treated as an unknown user if the
// private users/{uid} record already exists.
export const ensureLegacyProfile = onCall(
  { enforceAppCheck: true, maxInstances: 10 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
    await enforceRateLimit(uid, "profile_bootstrap", 10, 60 * 60_000);

    const profileRef = db.collection("profiles").doc(uid);
    const userRef = db.collection("users").doc(uid);
    const [profile, legacyUser, account] = await Promise.all([
      profileRef.get(),
      userRef.get(),
      getAuth().getUser(uid),
    ]);
    if (profile.exists) return { ready: true };
    if (!legacyUser.exists) return { ready: false };

    const data = legacyUser.data() ?? {};
    const email = (account.email ?? data.email ?? "").trim().toLowerCase();
    const username = typeof data.username === "string" && data.username.trim()
      ? data.username.trim()
      : (account.displayName?.trim() || email.split("@")[0] || "");
    if (!username) return { ready: false };

    const photoURL = account.photoURL ?? data.profile_photo ?? data.photoURL ?? "";
    const usernameLower = username.toLowerCase();
    const now = FieldValue.serverTimestamp();
    await profileRef.set({
      user_id: uid,
      username,
      username_lower: usernameLower,
      profile_photo: photoURL,
      email_hash: email ? createHash("sha256").update(email, "utf8").digest("hex") : "",
      status: "online",
      last_active_at: now,
      migrated_at: now,
    }, { merge: true });

    return { ready: true };
  },
);

export const searchUsers = onCall(
  { enforceAppCheck: true, maxInstances: 10 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in is required.");
    await enforceRateLimit(uid, "profile_search", 30, 60_000);

    if (typeof request.data?.query !== "string") {
      throw new HttpsError("invalid-argument", "Enter a username or full email.");
    }
    const term = request.data.query.trim().toLowerCase();
    if (term.length < 2 || term.length > 254) return { users: [] };

    let snapshot;
    if (term.includes("@")) {
      const emailHash = createHash("sha256").update(term, "utf8").digest("hex");
      snapshot = await db.collection("profiles")
        .where("email_hash", "==", emailHash)
        .limit(10)
        .get();
    } else {
      snapshot = await db.collection("profiles")
        .orderBy("username_lower")
        .startAt(term)
        .endAt(term + "\\uf8ff")
        .limit(11)
        .get();
    }

    const users = snapshot.docs
      .filter((doc) => doc.id !== uid)
      .slice(0, 10)
      .map((doc) => {
        const data = doc.data();
        return {
          user_id: doc.id,
          username: typeof data.username === "string" ? data.username : "Kakarot user",
          profile_photo: typeof data.profile_photo === "string" ? data.profile_photo : "",
          status: data.status === "online" ? "online" : "offline",
        };
      });
    return { users };
  },
);
