// app/javascript/controllers/offline_form_controller.js
import { Controller } from "@hotwired/stimulus"
import { openDB } from 'idb';

export default class extends Controller {
  static targets = ["form"]

  async connect() {
    // Ouvre (ou crée) la base de données IndexedDB
    this.db = await openDB('bastair-offline-db', 1, {
      upgrade(db) {
        // Crée un "object store" (similaire à une table) pour les signalements en attente
        db.createObjectStore('pending-signalements', { keyPath: 'id', autoIncrement: true });
      },
    });
  }

  async submit(event) {
    // Si on est en ligne, on laisse le formulaire se soumettre normalement
    if (navigator.onLine) {
      return;
    }

    // Si on est hors ligne, on empêche la soumission classique
    event.preventDefault();

    const form = this.formTarget;
    const formData = new FormData(form);
    const signalementData = {
      description: formData.get('signalement[description]'),
      avion_id: form.dataset.avionId, // On récupère l'ID de l'avion depuis le formulaire
      csrfToken: document.querySelector('meta[name="csrf-token"]').content
    };

    // On sauvegarde les données dans IndexedDB
    await this.db.add('pending-signalements', signalementData);

    // On demande au Service Worker de lancer une synchronisation dès que possible
    if ('serviceWorker' in navigator && 'SyncManager' in window) {
      const registration = await navigator.serviceWorker.ready;
      await registration.sync.register('sync-new-signalement');
    }

    // On informe l'utilisateur que son signalement a été sauvegardé
    // et sera envoyé plus tard.
    alert("Vous êtes hors ligne. Votre signalement a été sauvegardé et sera envoyé dès que vous retrouverez une connexion.");
    
    // On redirige l'utilisateur vers la page d'accueil
    window.location.href = '/';
  }
}
