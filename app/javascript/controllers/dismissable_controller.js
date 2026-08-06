import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  dismiss() {
    const csrfTag = document.querySelector("meta[name='csrf-token']")

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": csrfTag ? csrfTag.content : "",
        "Accept": "application/json"
      }
    })

    this.element.classList.add("opacity-0", "translate-y-[-1rem]", "transition-all", "duration-300")
    setTimeout(() => this.element.remove(), 300)
  }
}
