/*
  Firebase Messaging Service Worker (Web Push)
  - Handles background notifications when the page is closed or inactive
  - Must be served from the root (/) of your domain
*/

/* Use the compat builds for SW for simpler setup */
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// IMPORTANT: Keep this config in sync with your web app
firebase.initializeApp({
  apiKey: "AIzaSyBLkw6NAJnbXgHVfS7EKyDTzZx_m5lEI4I",
  authDomain: "cloud-comuting-ccc74.firebaseapp.com",
  projectId: "cloud-comuting-ccc74",
  storageBucket: "cloud-comuting-ccc74.firebasestorage.app",
  messagingSenderId: "571964573753",
  appId: "1:571964573753:web:26666c90b67d567c5ba5e8",
  measurementId: "G-Y6BJVVWWD9"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'New Message';
  const options = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
    vibrate: [100, 50, 100]
  };
  self.registration.showNotification(title, options);
});

// Optional: Click handling to focus an existing client
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow('/notifications');
    })
  );
});
