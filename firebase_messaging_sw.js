importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js','https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

// Config is passed by index.html in the registration URL (?c=...), so it lives in one place only.
const cfg = JSON.parse(new URL(self.location.href).searchParams.get('c') || '{}');

if (cfg.apiKey) {
  firebase.initializeApp(cfg);
  firebase.messaging().onBackgroundMessage(p => {
    const d = p.data || {};
    return self.registration.showNotification(d.title || 'Kakarot Chat', { body: d.body || '', tag: d.chat || 'kk' });
  });
}

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(clients.matchAll({ type: 'window', includeUncontrolled: true })
    .then(l => (l.length ? l[0].focus() : clients.openWindow('./'))));
});
