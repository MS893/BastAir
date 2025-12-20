import { Controller } from "@hotwired/stimulus"
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

  // Helper pour redimensionner l'image à 50%
  getResizedSignature() {
    const ratio = 0.5;
    const canvas = this.canvasTarget;
    const tempCanvas = document.createElement('canvas');
    const tempCtx = tempCanvas.getContext('2d');

    tempCanvas.width = canvas.width * ratio;
    tempCanvas.height = canvas.height * ratio;

    tempCtx.drawImage(canvas, 0, 0, tempCanvas.width, tempCanvas.height);

    return tempCanvas.toDataURL('image/png');
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

    // 1. Convertit la signature en Data URL (Base64) format PNG avec redimensionnement à 50%
    const dataURL = this.getResizedSignature();

    // 2. Stocke la chaîne Base64 dans le champ caché
    this.inputTarget.value = dataURL;

    // 3. Soumet le formulaire manuellement (nécessaire car le bouton est de type "button")
    this.element.submit();
  }

}
