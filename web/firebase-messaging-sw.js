/* Service worker do push web. O token é criado pelo firebase_messaging no app. */
self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = { notification: { body: event.data ? event.data.text() : '' } };
  }
  const notification = payload.notification || {};
  const data = payload.data || {};
  const title = notification.title || data.titulo || 'Eu Atleta';
  const options = {
    body: notification.body || data.corpo || 'Você recebeu uma nova atualização.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: { ...data, url: data.url || '/' },
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = event.notification.data?.url || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windows) => {
      for (const client of windows) {
        if ('focus' in client) {
          client.navigate(targetUrl);
          return client.focus();
        }
      }
      return clients.openWindow ? clients.openWindow(targetUrl) : undefined;
    }),
  );
});
