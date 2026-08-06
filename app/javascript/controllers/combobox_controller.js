import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list", "hiddenId"]
  static values = { url: String, dependsOnId: String }

  connect() {
    this.options = []
    this.open = false

    if (this.hasDependsOnIdValue && this.dependsOnIdValue) {
      this.parentInput = document.getElementById(this.dependsOnIdValue)
      if (this.parentInput) {
        this.parentInput.addEventListener("combobox:change", this.parentChanged.bind(this))
      }
    } else {
      this.fetchOptions(this.urlValue)
    }

    document.addEventListener("click", this.outsideClick.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick.bind(this))
    if (this.parentInput) {
      this.parentInput.removeEventListener("combobox:change", this.parentChanged.bind(this))
    }
  }

  async fetchOptions(url) {
    if (!url || url.includes(":make_id")) return

    try {
      const response = await fetch(url, { headers: { "Accept": "application/json" } })
      this.options = await response.json()
    } catch {
      this.options = []
    }
  }

  parentChanged(event) {
    const parentId = event.detail.id
    this.inputTarget.value = ""
    this.hiddenIdTarget.value = ""

    if (parentId) {
      const url = this.urlValue.replace(":make_id", parentId).replace("%3Amake_id", parentId)
      this.fetchOptions(url)
    } else {
      this.options = []
    }

    this.render([])
    this.close()
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    this.hiddenIdTarget.value = ""

    if (query.length === 0) {
      this.render(this.options)
    } else {
      const filtered = this.options.filter(o => o.name.toLowerCase().includes(query))
      this.render(filtered)
    }

    this.openList()
    this.dispatchChange()
  }

  openList() {
    this.open = true
    this.listTarget.classList.remove("hidden")
  }

  close() {
    this.open = false
    this.listTarget.classList.add("hidden")
  }

  render(items) {
    this.listTarget.innerHTML = ""

    items.forEach(item => {
      const li = document.createElement("li")
      li.textContent = item.name
      li.dataset.id = item.id
      li.className = "px-3 py-2 cursor-pointer hover:bg-gray-100 text-sm"
      li.addEventListener("mousedown", (e) => {
        e.preventDefault()
        this.select(item)
      })
      this.listTarget.appendChild(li)
    })
  }

  select(item) {
    this.inputTarget.value = item.name
    this.hiddenIdTarget.value = item.id
    this.close()
    this.dispatchChange()
  }

  dispatchChange() {
    this.inputTarget.dispatchEvent(new CustomEvent("combobox:change", {
      detail: { id: this.hiddenIdTarget.value, name: this.inputTarget.value },
      bubbles: true
    }))
  }

  outsideClick(event) {
    if (this.open && !this.element.contains(event.target)) {
      this.close()
    }
  }

  focusOpen() {
    if (this.options.length > 0) {
      const query = this.inputTarget.value.trim().toLowerCase()
      if (query.length === 0) {
        this.render(this.options)
      } else {
        const filtered = this.options.filter(o => o.name.toLowerCase().includes(query))
        this.render(filtered)
      }
      this.openList()
    }
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.inputTarget.blur()
    }
  }
}
