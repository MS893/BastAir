import { Controller } from "@hotwired/stimulus"

// Se connecte à data-controller="reservation-form"
export default class extends Controller {
  // Définit les "cibles" que notre contrôleur peut manipuler.
  // Ici, c'est la div qui contient la liste des instructeurs.
  static targets = [ "instructorSelect" ]

  // Cette méthode est appelée automatiquement lorsque le contrôleur est chargé.
  connect() {
    // On appelle immédiatement la méthode pour définir l'état initial du formulaire.
    this.toggleInstructor()
  }

  // Cette méthode est appelée à chaque fois que la case à cocher change.
  toggleInstructor() {
    // On récupère l'état de la case à cocher.
    const isInstruction = this.element.querySelector('#reservation_instruction').checked
    // On affiche ou on masque la div des instructeurs en fonction de l'état.
    this.instructorSelectTarget.style.display = isInstruction ? "block" : "none"
  }
}
