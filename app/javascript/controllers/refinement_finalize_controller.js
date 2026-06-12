import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog", "form" ]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  confirm() {
    if (!this.hasFormTarget) return

    this.formTarget.requestSubmit()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
