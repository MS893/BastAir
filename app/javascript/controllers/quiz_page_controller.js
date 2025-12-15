import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

// Connects to data-controller="quiz-page"
export default class extends Controller {
  static targets = ["modal", "signatureSection"]

  connect() {
    this.modal = new Modal(this.modalTarget)
  }

  handleQuizSuccess() {
    // Ferme la modale
    this.modal.hide()

    // Affiche la section de signature
    this.signatureSectionTarget.classList.remove('d-none')
  }
}