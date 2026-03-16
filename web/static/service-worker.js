// Basic Service Worker for PWA installation requirements
const CACHE_NAME = 'nomimane-v1';

self.addEventListener('install', (event) => {
  console.log('[Service Worker] Install');
});

self.addEventListener('fetch', (event) => {
  // Pass-through for now, just to satisfy the manifest requirement
  // event.respondWith(fetch(event.request));
});
