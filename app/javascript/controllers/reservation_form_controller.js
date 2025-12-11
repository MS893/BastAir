import { Controller } from "@hotwired/stimulus"

// Se connecte à data-controller="reservation-form"
export default class extends Controller {
  // Définit les "cibles" que notre contrôleur peut manipuler.
  static targets = [
    "instructorSelect",
    "startDate", "endDate",
    "startTime", // Heure de début (select)
    "startMinute",// Minute de début (select)
    "endMinute",
    "endTime", // Heure de fin (select),
    "avionSelect", // Le select pour l'avion
    "signalementsFrame" // Le Turbo Frame pour les signalements
  ]

  // Cette méthode est appelée automatiquement lorsque le contrôleur est chargé.
  connect() {
    // On appelle immédiatement la méthode pour définir l'état initial du formulaire.
    this.toggleInstructor()
    // On vérifie si le formulaire est pour une nouvelle réservation (pas d'ID dans l'URL)
    // On charge les signalements pour l'avion sélectionné par défaut.
    this.updateSignalements();
    // On charge les dispos instructeurs.
    this.updateInstructors();
    // ou une modification. On n'ajuste l'heure que pour les nouvelles réservations.
    if (!window.location.pathname.includes('/edit')) {
      this.adjustEndTime();
    }
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
  // La méthode initTimeInputs n'est plus nécessaire, son rôle est pris par adjustEndTime au `connect`.

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
    // Récupère l'heure de début sélectionnée et la convertit en nombre.
    const startHour = parseInt(this.startTimeTarget.value);

    // Calcule l'heure de fin (heure de début + 1).
    let endHour = startHour + 1;

    // Gère le cas où l'heure de fin dépasse la limite de 18h.
    // Si startHour est 17, endHour sera 18. Si startHour est plus grand, on réinitialise.
    if (endHour > 18) {
      endHour = 18; // On plafonne à 18, qui est la dernière option valide.
    }

    // Met à jour l'heure de fin dans le selecteur.
    // La valeur doit être une chaîne de caractères pour correspondre aux options du <select>.
    this.endTimeTarget.value = endHour.toString();

    // Met les minutes de fin à 00.
    if (this.hasEndMinuteTarget) {
      this.endMinuteTarget.value = "0";
    }
  }

  // Met à jour le Turbo Frame des signalements quand un avion est sélectionné
  updateSignalements() {
    const avionId = this.avionSelectTarget.value;

    if (avionId) {
      // Construit l'URL pour l'action signalements_list
      const url = `/avions/${avionId}/signalements_list`;
      // Met à jour l'attribut 'src' du turbo-frame, ce qui déclenchera le chargement
      this.signalementsFrameTarget.src = url;
    } else {
      // Si aucun avion n'est sélectionné, on vide le contenu du frame
      this.signalementsFrameTarget.innerHTML = "";
    }
  }
  
  // --- Logique pour les instructeurs ---
  updateInstructors() {
  const date = this.startDateTarget.value
  const hour = this.startHourTarget.value
  const minute = this.startMinuteTarget.value

  // On s'assure que la date est bien sélectionnée
  if (!date) return;

  const url = `/reservations/fetch_available_instructors?date=${date}&hour=${hour}&minute=${minute}`

  fetch(url, {
    headers: {
      "Accept": "text/vnd.turbo-stream.html",
    }
  })
    .then(response => response.text())
    .then(html => {
      this.instructorSelectTarget.innerHTML = html
    })
    .catch(error => console.error("Error fetching instructors:", error));
  }

}
