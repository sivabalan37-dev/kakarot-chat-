// Service worker for Kakarot Chat push notifications. Upload it to the same folder as index.html.
importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAFwdmFRWWCGoej3IvEY17v_WhhaOkwtNE",
  authDomain: "kakarot-chat.firebaseapp.com",
  projectId: "kakarot-chat",
  storageBucket: "kakarot-chat.firebasestorage.app",
  messagingSenderId: "948236334962",
  appId: "1:948236334962:web:c08f4dd1465074a09a8feb"
});

firebase.messaging(); // shows the notification the server sends while the page is closed or in the background

self.addEventListener("notificationclick", (e) => {
  e.notification.close();
  e.waitUntil(clients.matchAll({ type: "window", includeUncontrolled: true })
    .then((cs) => (cs.length ? cs[0].focus() : clients.openWindow("./"))));
});
