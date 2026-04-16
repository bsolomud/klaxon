import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "input"]

  select(event) {
    const value = parseInt(event.target.closest("[data-value]")?.dataset.value || event.target.value)
    this.highlight(value)
  }

  highlight(value) {
    this.starTargets.forEach(star => {
      const starValue = parseInt(star.dataset.value)
      if (starValue <= value) {
        star.classList.remove("text-gray-300")
        star.classList.add("text-yellow-400")
      } else {
        star.classList.remove("text-yellow-400")
        star.classList.add("text-gray-300")
      }
    })
  }
}
