const cacheName = 'pwfilecache';

self.addEventListener('install', function(event) {
  // Skip the 'waiting' lifecycle phase, to go directly from 'installed' to 'activated', even if
  // there are still previous incarnations of this service worker registration active.
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', function(event) {
  // Claim any clients immediately, so that the page will be under SW control without reloading.
  event.waitUntil(self.clients.claim());
});

this.addEventListener('fetch', (event) => {
  console.log('Fetching ' + event.request.url);

  event.respondWith(
    fetch(`${event.request.url}?${Math.random()}`)
      .then((resp) => {
        // Check if we received a valid response
        if(resp && resp.ok) {
          console.log('Certified fresh!');

          let respClone = resp.clone();
          caches.open(cacheName).then((cache) => cache.put(event.request, respClone));
          return resp;
        } else {
          throw Error('response status ' + response.status);
        }
      })
      .catch((error) => caches.match(event.request))
  );
});
