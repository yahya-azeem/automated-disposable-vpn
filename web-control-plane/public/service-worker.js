const CACHE_NAME = 'trusttunnel-cache-v2';
const PRECACHE_ASSETS = [
  './',
  './index.html',
  './favicon.svg',
  './icons.svg',
  './icon-192.png',
  './icon-512.png',
  './manifest.json'
];

// Install Event - Pre-cache essential resources
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Pre-caching assets...');
        return cache.addAll(PRECACHE_ASSETS);
      })
      .then(() => self.skipWaiting())
  );
});

// Activate Event - Clean up old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch Event - Intercept and handle cache/network strategies
self.addEventListener('fetch', event => {
  const requestUrl = new URL(event.request.url);
  
  // Only handle local origin requests (ignore API requests to github.com)
  if (requestUrl.origin === self.location.origin) {
    const isHtml = event.request.headers.get('accept') && event.request.headers.get('accept').includes('text/html');
    
    if (isHtml) {
      // Network-First strategy for HTML files to ensure updates are seen immediately
      event.respondWith(
        fetch(event.request)
          .then(networkResponse => {
            if (networkResponse.status === 200) {
              const responseToCache = networkResponse.clone();
              caches.open(CACHE_NAME).then(cache => cache.put(event.request, responseToCache));
            }
            return networkResponse;
          })
          .catch(() => {
            // Fall back to cached HTML if network is unavailable
            return caches.match(event.request) || caches.match('./') || caches.match('./index.html');
          })
      );
    } else {
      // Cache-First with Stale-While-Revalidate for non-HTML static assets
      event.respondWith(
        caches.match(event.request).then(cachedResponse => {
          if (cachedResponse) {
            // Fetch updated version in the background to update cache
            fetch(event.request).then(networkResponse => {
              if (networkResponse.status === 200) {
                caches.open(CACHE_NAME).then(cache => cache.put(event.request, networkResponse));
              }
            }).catch(() => {/* Ignore network errors offline */});
            
            return cachedResponse;
          }

          return fetch(event.request).then(networkResponse => {
            if (!networkResponse || networkResponse.status !== 200) {
              return networkResponse;
            }

            const responseToCache = networkResponse.clone();
            caches.open(CACHE_NAME).then(cache => {
              cache.put(event.request, responseToCache);
            });

            return networkResponse;
          });
        })
      );
    }
  }
});

