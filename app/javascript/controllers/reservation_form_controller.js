import { Controller } from "@hotwired/stimulus"

// Se connecte à data-controller="reservation-form"
export default class extends Controller {
  // Définit les "cibles" que notre contrôleur peut manipuler.
  static targets = [
    "instructorSelect",
    "startDate", "endDate",
    "startTime", // Heure de début (select)
    "startMinute", // Minute de début (select)
    "endTime", // Heure de fin (select)
  ]

  // Cette méthode est appelée automatiquement lorsque le contrôleur est chargé.
  connect() {
    // On appelle immédiatement la méthode pour définir l'état initial du formulaire.
    this.toggleInstructor()
    this.initTimeInputs()
  }

  // Cette méthode est appelée à chaque fois que la case à cocher change.
  toggleInstructor() {
    // On récupère l'état de la case à cocher.
    const isInstruction = this.element.querySelector('#reservation_instruction').checked
    if (this.hasInstructorSelectTarget) {
      // On affiche ou on masque la div des instructeurs en fonction de l'état.
      this.instructorSelectTarget.style.display = isInstruction ? "block" : "none"
    }
  }

  // --- Logique pour les dates et heures ---

  // Initialise les champs de saisie de l'heure
  initTimeInputs() {
    // Plus nécessaire avec les listes déroulantes
  }

  // Met à jour la date de fin quand la date de début change
  updateEndDate() {
    if (this.hasStartDateTarget && this.hasEndDateTarget) {
      this.endDateTarget.value = this.startDateTarget.value;
    }
    // Après avoir changé la date, on ajuste aussi l'heure de fin.
    this.adjustEndTime();
  }

  // S'assure que l'heure de fin est toujours après l'heure de début
  adjustEndTime() {
    // Cette logique est maintenant simplifiée car gérée par les options des listes déroulantes.
    // On pourrait ajouter une validation plus complexe si nécessaire, mais pour l'instant,
    // la logique de base est de s'assurer que la date de fin suit la date de début.
    const startDateValue = this.startDateTarget.value;
    const endDateValue = this.endDateTarget.value;

    // Si la date de fin devient antérieure à la date de début, on la réinitialise.
    if (endDateValue < startDateValue) {
      this.endDateTarget.value = startDateValue;
    }
  }

}
