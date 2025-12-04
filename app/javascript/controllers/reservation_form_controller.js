import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reservation-form"
export default class extends Controller {
  static targets = [ "instructionCheckbox", "instructorSelect" ]

  connect() {
    // On vérifie l'état initial de la case à cocher au chargement de la page
    // pour afficher le menu si la réservation est déjà en instruction (cas de la modification).
    this.toggle();
  }

  toggle() {
    // On affiche ou on masque le menu déroulant en fonction de l'état de la case à cocher.
    // La classe 'd-none' de Bootstrap est utilisée pour masquer l'élément.
    this.instructorSelectTarget.classList.toggle("d-none", !this.instructionCheckboxTarget.checked);
  }
}
