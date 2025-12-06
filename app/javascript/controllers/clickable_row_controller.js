import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="clickable-row"
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.addEventListener("click", this.navigate.bind(this))
  }

  navigate() {
    Turbo.visit(this.urlValue)
  }

  stop(event) {
    event.stopPropagation()
  }
}
