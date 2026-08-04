import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

// Interactive location picker for the workshop form. "Locate by address" geocodes
// the typed address (server endpoint) and drops a draggable pin; clicking the map
// or dragging the pin also works. The chosen point is written into hidden lat/lng
// fields, and a flag tells the server not to re-geocode over the map choice.
export default class extends Controller {
  static targets = ["canvas", "lat", "lng", "flag", "status"]
  static values = { lat: Number, lng: Number, geocodeUrl: String, notFound: String }

  static PIN_HTML = `
    <svg viewBox="0 0 24 24" width="30" height="30" fill="#000" stroke="#fff" stroke-width="1.5"
         style="filter: drop-shadow(0 1px 2px rgba(0,0,0,.4))">
      <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/>
      <circle cx="12" cy="9" r="2.5" fill="#fff" stroke="none"/>
    </svg>`

  connect() {
    const hasPoint = Boolean(this.latValue && this.lngValue)
    const center = hasPoint ? [this.latValue, this.lngValue] : [50.4501, 30.5234]

    this.map = L.map(this.canvasTarget).setView(center, hasPoint ? 15 : 11)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
      maxZoom: 19
    }).addTo(this.map)

    this.icon = L.divIcon({ html: this.constructor.PIN_HTML, className: "", iconSize: [30, 30], iconAnchor: [15, 30] })
    this.marker = null
    if (hasPoint) this.place(center[0], center[1], false)

    this.map.on("click", (event) => this.place(event.latlng.lat, event.latlng.lng))
    setTimeout(() => this.map && this.map.invalidateSize(), 100)
  }

  async locate(event) {
    event.preventDefault()
    this.clearStatus()

    const form = this.element.closest("form")
    const value = (name) => form?.querySelector(`[name='workshop[${name}]']`)?.value || ""
    const query = new URLSearchParams({ address: value("address"), city: value("city"), country: value("country") })

    try {
      const response = await fetch(`${this.geocodeUrlValue}?${query}`, { headers: { Accept: "application/json" } })
      if (!response.ok) return this.showStatus(this.notFoundValue)

      const data = await response.json()
      this.place(data.lat, data.lng)
      this.map.setView([data.lat, data.lng], 16)
    } catch {
      this.showStatus(this.notFoundValue)
    }
  }

  place(lat, lng, writeFields = true) {
    if (this.marker) {
      this.marker.setLatLng([lat, lng])
    } else {
      this.marker = L.marker([lat, lng], { icon: this.icon, draggable: true }).addTo(this.map)
      this.marker.on("dragend", () => {
        const point = this.marker.getLatLng()
        this.write(point.lat, point.lng)
      })
    }
    if (writeFields) this.write(lat, lng)
  }

  write(lat, lng) {
    this.latTarget.value = lat
    this.lngTarget.value = lng
    if (this.hasFlagTarget) this.flagTarget.value = "1"
    this.clearStatus()
  }

  showStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  clearStatus() {
    if (this.hasStatusTarget) this.statusTarget.textContent = ""
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }
}
