// Firebase client initialisation. This is the only place the web config lives.
// The web config is public by design; real protection comes from Firestore Security Rules.
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyDTH_wAVfuRL_cT2-iY3QbWK2HuEmbWCVc",
  authDomain: "kakarot-chat-web.firebaseapp.com",
  projectId: "kakarot-chat-web",
  storageBucket: "kakarot-chat-web.firebasestorage.app",
  messagingSenderId: "976639131346",
  appId: "1:976639131346:web:4b0802ee7e58a6b801b70b"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
