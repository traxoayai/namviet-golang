importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBKhmtCFW1ba7QLuvszHj-pBmWSvclPeMk",
  authDomain: "admin-namviet-erp.firebaseapp.com",
  projectId: "admin-namviet-erp",
  storageBucket: "admin-namviet-erp.firebasestorage.app",
  messagingSenderId: "925538350908",
  appId: "1:925538350908:web:c94013f695e4f2105e1039"
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Nhận tin nhắn ngầm ', payload);
  const notificationTitle = payload.notification?.title || 'Thông báo mới';
  const notificationOptions = {
    body: payload.notification?.body || 'Bạn có thông báo mới',
    icon: '/logo-namviet.png',
    data: {
      url: payload.data?.click_action || payload.fcmOptions?.link || payload.notification?.click_action || '/'
    }
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Click thông báo: ', event);
  event.notification.close();

  // Try to get URL from various payload fields
  const targetUrl = event.notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      // Check if there is already a window/tab open with the target URL
      for (let i = 0; i < windowClients.length; i++) {
        const client = windowClients[i];
        if (client.url.includes(targetUrl) && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
