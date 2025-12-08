import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="transaction-form"
export default class extends Controller {
  static targets = ["mouvement", "source"]

  connect() {
    this.loadCategories()
  }

  async loadCategories() {
    const response = await fetch('/categories')
    this.categories = await response.json()
    this.updateSourceOptions() // Update on page load
  }

  updateSourceOptions() {
    const selectedMouvement = this.mouvementTarget.value
    const options = selectedMouvement === 'Recette' ? this.categories.recette : this.categories.depense

    // On sauvegarde la valeur actuellement sélectionnée pour la restaurer si possible
    const currentSource = this.sourceTarget.value

    // Clear existing options
    this.sourceTarget.innerHTML = ""

    // Add a blank option
    const blankOption = document.createElement('option')
    blankOption.value = ''
    blankOption.text = 'Sélectionner une origine...'
    this.sourceTarget.appendChild(blankOption)

    // Add new options
    options.forEach(optionText => {
      const option = document.createElement('option')
      option.value = optionText
      option.text = optionText
      this.sourceTarget.appendChild(option)
    })

    // On essaie de restaurer la sélection précédente si elle est valide dans la nouvelle liste
    this.sourceTarget.value = currentSource
  }
}
