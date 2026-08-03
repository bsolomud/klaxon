import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

// Renders an OpenStreetMap/Leaflet map (no API key required). Leaflet ships from
// vendor/ (no runtime CDN dependency). Used on the workshops index (many pins)
// and workshop show (single pin).
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    points: { type: Array, default: [] },
    lat: { type: Number, default: 50.4501 },
    lng: { type: Number, default: 30.5234 },
    zoom: { type: Number, default: 12 }
  }

  // A self-contained SVG pin, so we depend on no marker image assets.
  static PIN_HTML = `
    <svg viewBox="0 0 24 24" width="30" height="30" fill="#000" stroke="#fff" stroke-width="1.5"
         style="filter: drop-shadow(0 1px 2px rgba(0,0,0,.4))">
      <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/>
      <circle cx="12" cy="9" r="2.5" fill="#fff" stroke="none"/>
    </svg>`

  connect() {
    const element = this.hasCanvasTarget ? this.canvasTarget : this.element
    this.map = L.map(element).setView([this.latValue, this.lngValue], this.zoomValue)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
      maxZoom: 19
    }).addTo(this.map)

    const icon = L.divIcon({
      html: this.constructor.PIN_HTML,
      className: "",
      iconSize: [30, 30],
      iconAnchor: [15, 30],
      popupAnchor: [0, -28]
    })

    const markers = this.pointsValue
      .filter((point) => point.lat && point.lng)
      .map((point) => {
        const marker = L.marker([point.lat, point.lng], { icon }).addTo(this.map)
        if (point.name) {
          marker.bindPopup(point.url ? `<a href="${point.url}">${point.name}</a>` : point.name)
        }
        return marker
      })

    if (markers.length > 1) {
      this.map.fitBounds(L.featureGroup(markers).getBounds().pad(0.2))
    }

    // Turbo/flex layouts can leave the container sized 0 at connect; recompute
    // once the browser has painted so tiles fill the box.
    setTimeout(() => this.map && this.map.invalidateSize(), 100)
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
