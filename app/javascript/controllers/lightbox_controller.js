import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template"]

  connect() {
    this.currentIndex = 0
    this.images = []
    this.overlay = null
    this.handleKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    this.close()
  }

  open(event) {
    const index = parseInt(event.params.index || 0, 10)
    this.loadImages()
    if (this.images.length === 0) return

    this.currentIndex = index
    this.buildOverlay()
    this.showImage()
    document.addEventListener("keydown", this.handleKeydown)
    document.body.style.overflow = "hidden"
  }

  close() {
    if (this.overlay) {
      this.overlay.remove()
      this.overlay = null
    }
    document.removeEventListener("keydown", this.handleKeydown)
    document.body.style.overflow = ""
  }

  next() {
    if (this.images.length === 0) return
    this.currentIndex = (this.currentIndex + 1) % this.images.length
    this.showImage()
  }

  prev() {
    if (this.images.length === 0) return
    this.currentIndex = (this.currentIndex - 1 + this.images.length) % this.images.length
    this.showImage()
  }

  // Private

  loadImages() {
    if (!this.hasTemplateTarget) return
    const imgs = this.templateTarget.content.querySelectorAll("img")
    this.images = Array.from(imgs).map((img) => img.dataset.src)
  }

  buildOverlay() {
    if (this.overlay) return

    this.overlay = document.createElement("div")
    this.overlay.className = "fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm"
    this.overlay.innerHTML = `
      <button data-action="click->lightbox#close" class="absolute top-4 right-4 text-white/80 hover:text-white z-10 cursor-pointer" aria-label="Close">
        <svg class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
        </svg>
      </button>
      <button data-action="click->lightbox#prev" class="absolute left-4 text-white/80 hover:text-white z-10 cursor-pointer" aria-label="Previous">
        <svg class="h-10 w-10" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
        </svg>
      </button>
      <button data-action="click->lightbox#next" class="absolute right-4 text-white/80 hover:text-white z-10 cursor-pointer" aria-label="Next">
        <svg class="h-10 w-10" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
        </svg>
      </button>
      <img class="max-h-[90vh] max-w-[90vw] object-contain select-none" data-lightbox-image alt="" />
      <div class="absolute bottom-4 text-white/60 text-sm" data-lightbox-counter></div>
    `

    // Close on backdrop click (not on buttons/image)
    this.overlay.addEventListener("click", (e) => {
      if (e.target === this.overlay) this.close()
    })

    document.body.appendChild(this.overlay)
  }

  showImage() {
    if (!this.overlay) return
    const img = this.overlay.querySelector("[data-lightbox-image]")
    const counter = this.overlay.querySelector("[data-lightbox-counter]")
    img.src = this.images[this.currentIndex]
    counter.textContent = `${this.currentIndex + 1} / ${this.images.length}`
  }

  handleKeydown(event) {
    switch (event.key) {
      case "Escape":
        this.close()
        break
      case "ArrowRight":
        this.next()
        break
      case "ArrowLeft":
        this.prev()
        break
    }
  }
}
