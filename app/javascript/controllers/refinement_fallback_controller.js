import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Polls only when Turbo Streams go quiet during processing (Action Cable unavailable or slow).
export default class extends Controller {
  static values = {
    processing: Boolean,
    url: String,
    interval: { type: Number, default: 10000 }
  }

  connect() {
    if (!this.processingValue) return

    this.lastStreamAt = Date.now()
    this.onStream = () => {
      this.lastStreamAt = Date.now()
    }

    document.addEventListener("turbo:before-stream-render", this.onStream)
    this.timer = window.setInterval(() => this.check(), this.intervalValue)
  }

  disconnect() {
    window.clearInterval(this.timer)
    document.removeEventListener("turbo:before-stream-render", this.onStream)
  }

  check() {
    if (Date.now() - this.lastStreamAt < this.intervalValue) return

    Turbo.visit(this.urlValue, { action: "replace" })
    this.lastStreamAt = Date.now()
  }
}
