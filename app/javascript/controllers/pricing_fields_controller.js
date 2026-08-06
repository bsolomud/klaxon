import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "fields"]

  connect() {
    this.toggle()
  }

  toggle() {
    this.fieldsTarget.classList.toggle("hidden", !this.checkboxTarget.checked)
  }
}
