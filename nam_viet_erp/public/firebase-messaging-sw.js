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
    icon: '/vite.svg'
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
