import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Renders an OpenStreetMap/Leaflet map (no API key required).
// Used on the workshops index (many pins) and workshop show (single pin).
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    points: { type: Array, default: [] },
    lat: { type: Number, default: 50.4501 },
    lng: { type: Number, default: 30.5234 },
    zoom: { type: Number, default: 12 }
  }

  connect() {
    const element = this.hasCanvasTarget ? this.canvasTarget : this.element
    this.map = L.map(element).setView([this.latValue, this.lngValue], this.zoomValue)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
      maxZoom: 19
    }).addTo(this.map)

    const markers = this.pointsValue
      .filter((point) => point.lat && point.lng)
      .map((point) => {
        const marker = L.marker([point.lat, point.lng]).addTo(this.map)
        if (point.name) {
          marker.bindPopup(point.url ? `<a href="${point.url}">${point.name}</a>` : point.name)
        }
        return marker
      })

    if (markers.length > 1) {
      this.map.fitBounds(L.featureGroup(markers).getBounds().pad(0.2))
    }
  }

  // Ask the browser for the user's location, then reload sorted by distance
  // using the existing `near=lat,lng` query the controller already supports.
  geolocate(event) {
    event.preventDefault()
    if (!navigator.geolocation) return

    navigator.geolocation.getCurrentPosition((position) => {
      const url = new URL(window.location.href)
      url.searchParams.set("near", `${position.coords.latitude},${position.coords.longitude}`)
      window.location.assign(url.toString())
    })
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }
}
