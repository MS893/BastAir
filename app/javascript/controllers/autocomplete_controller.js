import { Controller } from "@hotwired/stimulus"

// Ce contrôleur gère un champ de recherche avec autocomplétion.
export default class extends Controller {
  static targets = ["input", "hidden", "results"]

  connect() {
    // Ajoute un écouteur pour masquer les résultats si on clique n'importe où sur la page.
    // `this.hideResults.bind(this)` s'assure que `this` dans hideResults fait référence au contrôleur.
    document.addEventListener("click", this.hideResults.bind(this))
  }

  // Déclenché à chaque saisie dans le champ de recherche.
  search() {
    const query = this.inputTarget.value
    const url = `/users/search?query=${encodeURIComponent(query)}`

    // Met à jour la source du Turbo Frame, ce qui déclenche une requête vers notre action de recherche.
    this.resultsTarget.src = url
    this.resultsTarget.classList.remove("d-none") // Affiche la zone de résultats
  }

  // Déclenché au clic sur un résultat.
  select(event) {
    event.preventDefault()
    
    // Récupère l'ID et le nom depuis les data-attributes de l'élément cliqué.
    const userId = event.params.id
    const userName = event.params.name

    this.inputTarget.value = userName // Met à jour le champ visible
    this.hiddenTarget.value = userId  // Met à jour le champ caché qui sera soumis
    this.resultsTarget.classList.add("d-none") // Masque la zone de résultats
  }

  // Masque les résultats si le clic a lieu en dehors du composant d'autocomplétion.
  hideResults(event) {
    // `this.element` est l'élément principal du contrôleur (la div `data-controller="autocomplete"`)
    if (!this.element.contains(event.target)) {
      this.resultsTarget.classList.add("d-none")
    }
  }
}
