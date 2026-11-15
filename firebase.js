// Firebase client initialisation. This is the only place the web config lives.
// The web config is public by design; real protection comes from Firestore Security Rules.
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.10.0/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/11.10.0/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/11.10.0/firebase-firestore.js";
import { getStorage } from "https://www.gstatic.com/firebasejs/11.10.0/firebase-storage.js";

const firebaseConfig = {
  apiKey: "AIzaSyAFwdmFRWWCGoej3IvEY17v_WhhaOkwtNE",
  authDomain: "kakarot-chat.firebaseapp.com",
  projectId: "kakarot-chat",
  storageBucket: "kakarot-chat.firebasestorage.app",
  messagingSenderId: "948236334962",
  appId: "1:948236334962:web:c08f4dd1465074a09a8feb"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
