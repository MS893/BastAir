// app/javascripts/application.js
import "@hotwired/turbo-rails"
import "controllers"

//import "@popperjs/core";  // déjà importés dans application.html.erb
//import "bootstrap";

document.addEventListener("turbo:load", function () {
  var tooltipTriggerList = [].slice.call(
    document.querySelectorAll('[data-bs-toggle="tooltip"]')
  );
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });
});

// Enregistre le service worker pour la PWA
if (navigator.serviceWorker) {
  navigator.serviceWorker.register('/service-worker.js')
    .then(registration => {
      console.log('Service Worker enregistré avec succès:', registration);
    })
    .catch(error => {
      console.log('Échec de l\'enregistrement du Service Worker:', error);
    });
}
