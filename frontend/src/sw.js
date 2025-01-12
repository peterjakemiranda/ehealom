const CACHE_NAME = 'pawnshop-cache-v1';
const API_CACHE_NAME = 'pawnshop-api-cache-v1';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll([
        '/',
        '/index.html',
        '/favicon.ico',
        '/apple-touch-icon.png',
        '/masked-icon.svg',
        '/icons/icon-192x192.png',
        '/icons/icon-512x512.png',
        '/src/main.js',
        '/src/App.vue',
        '/src/router/index.js',
        '/src/stores/auth.js',
        '/src/assets/main.css',
      ]);
    })
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  
  // Special handling for API requests
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(
      fetch(event.request.clone())
        .catch(() => {
          // If offline, try to get from cache
          return caches.match(event.request);
        })
    );
    return;
  }

  // For non-API requests, try cache first
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});