import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="password-toggle"
export default class extends Controller {
  static targets = [ "input", "icon" ]

  connect() {
    // Optionnel: vous pouvez mettre du code ici si besoin à l'initialisation
  }

  toggle() {
    const isPassword = this.inputTarget.type === 'password';
    this.inputTarget.type = isPassword ? 'text' : 'password';

    // Change l'icône en fonction de l'état
    this.iconTarget.classList.toggle('bi-eye-slash', !isPassword);
    this.iconTarget.classList.toggle('bi-eye', isPassword);
  }
}
