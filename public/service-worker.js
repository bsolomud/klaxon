// AULABS push service worker. Shows an OS notification on push and opens the
// linked page on click.
self.addEventListener("push", (event) => {
  const data = event.data ? event.data.json() : {}
  event.waitUntil(
    self.registration.showNotification(data.title || "AULABS", {
      body: data.body || "",
      icon: "/icon.png",
      data: { path: data.path || "/" }
    })
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const path = (event.notification.data && event.notification.data.path) || "/"
  event.waitUntil(clients.openWindow(path))
})
