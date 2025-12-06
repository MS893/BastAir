import { Controller } from "@hotwired/stimulus"

// Ce contrôleur affiche une barre de progression lors des requêtes Turbo.
export default class extends Controller {
  static targets = ["bar"]

  connect() {
    // Masque la barre au cas où elle serait visible au chargement de la page.
    this.hide()

    // Écoute les événements Turbo pour afficher/masquer la barre.
    document.addEventListener("turbo:before-fetch-request", this.show.bind(this))
    document.addEventListener("turbo:render", this.hide.bind(this))
    document.addEventListener("turbo:submit-start", this.show.bind(this)) // Pour les formulaires
    document.addEventListener("turbo:submit-end", this.hide.bind(this))   // Pour les formulaires
  }

  show() {
    this.barTarget.style.width = '99%'
    this.barTarget.style.opacity = '1'
  }

  hide() {
    this.barTarget.style.width = '100%'
    this.barTarget.style.opacity = '0'
  }
}
