import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "submit", "body" ]

  submit() {
    if (!this.hasSubmitTarget || this.submitTarget.disabled) return

    this.submitTarget.disabled = true
    this.submitTarget.value = "Sending…"
    if (this.hasBodyTarget) this.bodyTarget.disabled = true
  }
}
