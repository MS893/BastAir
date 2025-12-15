import { Controller } from "@hotwired/stimulus"
// Importe la librairie que vous venez d'installer via Importmaps
import SignaturePad from "signature_pad"

export default class extends Controller {
  // Déclare les éléments HTML qu'on va manipuler : 
  // 1. Le canvas (la zone de dessin)
  // 2. Le champ caché (pour stocker la data Base64)
  static targets = ["canvas", "output"]

  connect() {
    console.log("Signature Controller connecté.");
    // Initialise Signature Pad sur l'élément canvas
    this.signaturePad = new SignaturePad(this.canvasTarget, {
      backgroundColor: 'rgb(255, 255, 255)', // Fond blanc (très important pour le PNG)
      penColor: 'rgb(0, 0, 0)',             // Stylo noir
      minWidth: 1,
      maxWidth: 3
    });
  }

  // Action pour effacer le dessin (appelée par un bouton HTML)
  clear() {
    this.signaturePad.clear();
  }

  // Action appelée lorsque le formulaire est soumis (important !)
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
