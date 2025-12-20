import { Controller } from "@hotwired/stimulus"
// Importe la librairie qui fonctionnait bien
import SignaturePad from "signature_pad"

export default class extends Controller {
  // Adaptation : "input" correspond à votre HTML actuel (au lieu de "output" dans la sauvegarde)
  static targets = ["canvas", "input"]
  // pour récupérer le nom à afficher
  static values = { signerName: String }

  connect() {
    console.log("Signature Controller connecté.");
    // Initialise Signature Pad sur l'élément canvas (Code restauré)
    this.signaturePad = new SignaturePad(this.canvasTarget, {
      backgroundColor: 'rgb(255, 255, 255)', // Fond blanc (très important pour le PNG)
      penColor: 'rgb(0, 0, 0)',              // Stylo noir
      minWidth: 1,
      maxWidth: 3
    });
  }

  // Action pour effacer le dessin
  clear() {
    this.signaturePad.clear();
  }

  // Action appelée au clic sur le bouton Valider
  submit(event) {
    event.preventDefault(); // Empêche le comportement par défaut

    if (this.signaturePad.isEmpty()) {
      alert("Veuillez apposer votre signature pour valider l'acquisition du cours.");
      return;
    }

    // --- Leçons en vol : Incrustation du nom du signataire ---
    if (this.hasSignerNameValue) {
      // On dessine directement sur le contexte du canvas géré par SignaturePad
      const ctx = this.canvasTarget.getContext("2d");
      ctx.font = "12px sans-serif";
      ctx.fillStyle = "#000000";
      ctx.textAlign = "center";
      // On écrit le texte centré en bas
      ctx.fillText(this.signerNameValue, this.canvasTarget.width / 2, this.canvasTarget.height - 10);
    }
    // ------------------------------------------------

    // 1. Convertit la signature en Data URL (Base64) format PNG (Code restauré)
    const dataURL = this.signaturePad.toDataURL('image/png');

    // 2. Stocke la chaîne Base64 dans le champ caché
    this.inputTarget.value = dataURL;

    // 3. Soumet le formulaire manuellement (nécessaire car le bouton est de type "button")
    this.element.submit();
  }

  // Action appelée lorsque le formulaire (FTP) est soumis (important !)
  save(event) {
    if (this.signaturePad.isEmpty()) {
      alert("Veuillez apposer votre signature pour valider l'acquisition du cours.");
      event.preventDefault(); // Empêche la soumission si le pad est vide
    } else {
      // 1. Convertit la signature en Data URL (Base64) format PNG
      // PNG est préférable pour conserver la transparence/qualité du trait.
      const dataURL = this.signaturePad.toDataURL('image/png');

      // 2. Stocke la chaîne Base64 dans le champ caché qui sera envoyé au serveur Rails
      this.outputTarget.value = dataURL;

      // Le formulaire continue sa soumission
    }
  }

}
