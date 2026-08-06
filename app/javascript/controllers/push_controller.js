import { Controller } from "@hotwired/stimulus"

// Registers the service worker and subscribes the browser to web push, then
// posts the subscription to the server. Requires a VAPID public key.
export default class extends Controller {
  static values = { publicKey: String }

  async subscribe(event) {
    event.preventDefault()
    if (!("serviceWorker" in navigator) || !("PushManager" in window) || !this.publicKeyValue) return

    const permission = await Notification.requestPermission()
    if (permission !== "granted") return

    const registration = await navigator.serviceWorker.register("/service-worker.js")
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(this.publicKeyValue)
    })

    const keys = subscription.toJSON().keys
    await fetch("/push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content
      },
      body: JSON.stringify({
        push_subscription: { endpoint: subscription.endpoint, p256dh_key: keys.p256dh, auth_key: keys.auth }
      })
    })
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const raw = atob(base64)
    return Uint8Array.from([...raw].map((char) => char.charCodeAt(0)))
  }
}
