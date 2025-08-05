import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  
  connect() {
    this.timeout = null
    this.form = this.element
  }
  
  perform() {
    clearTimeout(this.timeout)
    
    // Debounce the search to avoid too many requests
    this.timeout = setTimeout(() => {
      // Submit the form which will use Turbo
      this.form.requestSubmit()
    }, 300) // 300ms delay
  }
  
  disconnect() {
    clearTimeout(this.timeout)
  }
}