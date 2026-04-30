// Firebase version must match firebase_core package version used in Flutter.
// After running `flutterfire configure`, replace the config values below
// with the ones from your Firebase project (Console > Project Settings > General > Web apps).
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBhQw4awAFfnyYfx732B5LFZ59dZG4SZYo",
  authDomain: "reservaqui-45478.firebaseapp.com",
  projectId: "reservaqui-45478",
  storageBucket: "reservaqui-45478.firebasestorage.app",
  messagingSenderId: "153552996154",
  appId: "1:153552996154:web:087f6a391c143e522f3203",
  measurementId: "G-3NRWN1W7N4"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? "Nova notificação";
  const body = payload.notification?.body ?? "";
  self.registration.showNotification(title, {
    body,
    icon: "/icons/Icon-192.png",
  });
});
