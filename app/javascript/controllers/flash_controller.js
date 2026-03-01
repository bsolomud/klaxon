import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 5000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.durationValue)
  }

  close() {
    clearTimeout(this.timer)
    this.dismiss()
  }

  dismiss() {
    this.element.classList.add("opacity-0", "translate-x-full")
    setTimeout(() => this.element.remove(), 300)
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }
}
