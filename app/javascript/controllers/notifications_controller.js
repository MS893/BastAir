// app/javascript/controllers/notifications_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { vapidPublicKey: String }

  connect() {
    // Cache le bouton si les notifications ne sont pas supportées
    if (!("Notification" in window) || !("serviceWorker" in navigator)) {
      this.element.style.display = "none";
    }
  }

  async subscribe(event) {
    event.preventDefault();

    // Vérifie si la permission est déjà refusée
    if (Notification.permission === "denied") {
      this.dispatchToast("Notifications bloquées", "Veuillez les réactiver dans les paramètres de votre navigateur (via l'icône de cadenas).", "error");
      return;
    }

    // Demande la permission (ne s'affichera que si la permission est 'default')
    const permission = await Notification.requestPermission();

    if (permission === "granted") {
      try {
        const registration = await navigator.serviceWorker.ready;
        const subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.vapidPublicKeyValue,
        });
        await this.sendSubscriptionToServer(subscription);
        this.dispatchToast("Abonnement réussi !", "Vous êtes maintenant abonné aux notifications.", "success");
      } catch (error) {
        console.error("Erreur lors de l'abonnement aux notifications:", error);
        this.dispatchToast("Erreur d'abonnement", "Une erreur est survenue. Veuillez réessayer.", "error");
      } finally {
        this.element.remove(); // On supprime l'élément, que l'abonnement ait réussi ou non.
      }
    } else { // 'default' (si l'utilisateur ferme la fenêtre de permission) ou 'denied'
      this.dispatchToast("Abonnement annulé", "L'abonnement aux notifications a été annulé ou refusé.", "info");
      this.element.remove(); // On supprime aussi l'élément du contrôleur en cas de refus
    }
  }

  // Méthode pour déclencher l'événement qui sera intercepté par le toast_controller
  dispatchToast(title, message, type) {
    const event = new CustomEvent("toast:show", {
      detail: {
        title: title,
        message: message,
        type: type, // 'success', 'error', ou 'info'
      }
    });
    document.dispatchEvent(event);
  }

  async sendSubscriptionToServer(subscription) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    const response = await fetch("/web_push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({ subscription: subscription.toJSON() }),
    });

    // fetch() ne considère pas les erreurs HTTP (comme 4xx, 5xx) comme des erreurs réseau.
    // Il faut donc vérifier manuellement si la réponse est "ok" (statut 200-299).
    if (!response.ok) {
      throw new Error(`Le serveur a répondu avec le statut ${response.status}`);
    }
  }
}
