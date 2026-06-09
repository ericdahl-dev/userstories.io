import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "feedback" ]
  static values = { text: String }

  async copy() {
    const text = this.textValue
    if (!text) return

    try {
      await navigator.clipboard.writeText(text)
      this.showFeedback()
    } catch {
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.setAttribute("readonly", "")
    textarea.style.position = "absolute"
    textarea.style.left = "-9999px"
    document.body.appendChild(textarea)
    textarea.select()

    try {
      document.execCommand("copy")
      this.showFeedback()
    } finally {
      document.body.removeChild(textarea)
    }
  }

  showFeedback() {
    if (!this.hasFeedbackTarget) return

    this.feedbackTarget.classList.remove("hidden")
    window.clearTimeout(this.feedbackTimeout)
    this.feedbackTimeout = window.setTimeout(() => {
      this.feedbackTarget.classList.add("hidden")
    }, 2000)
  }
}
