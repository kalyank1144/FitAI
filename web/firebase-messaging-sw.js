// Firebase Messaging service worker (web)
// Replace with your real Firebase config or use FlutterFire (firebase_options.dart) which injects at runtime.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
