import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="bia-form"
export default class extends Controller {
  static targets = ["field", "form", "personalInfoTitle", "loginInfoTitle", "clubInfoTitle"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const prenomInput = this.formTarget.querySelector("#user_prenom");
    const isBia = prenomInput.value.trim().toLowerCase() === 'bia';

    this.fieldTargets.forEach(field => {
      field.style.display = isBia ? 'none' : '';
    });

    // Change titles if it's a BIA account
    if (isBia) {
      if (this.hasPersonalInfoTitleTarget) this.personalInfoTitleTarget.innerText = "Coordonnées collège ou lycée";
      if (this.hasLoginInfoTitleTarget) this.loginInfoTitleTarget.innerText = "Contact";
      if (this.hasClubInfoTitleTarget) this.clubInfoTitleTarget.innerText = "Compte";
    } else {
      if (this.hasPersonalInfoTitleTarget) this.personalInfoTitleTarget.innerText = "Informations Personnelles";
      if (this.hasLoginInfoTitleTarget) this.loginInfoTitleTarget.innerText = "Informations de Connexion";
      if (this.hasClubInfoTitleTarget) this.clubInfoTitleTarget.innerText = "Informations Club";
    }

    const autoriseCheckbox = this.formTarget.querySelector("#user_autorise");
    if (isBia && autoriseCheckbox) {
      autoriseCheckbox.checked = true;
    }

    const fonctionSelect = this.formTarget.querySelector("#user_fonction");
    if (isBia && fonctionSelect) {
      // valeur par défaut
    }
  }
}
