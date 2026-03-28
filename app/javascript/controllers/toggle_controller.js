import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  toggle() {
    const el = document.getElementById(this.targetValue)
    if (el) el.classList.toggle("hidden")
  }
}
