import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quiz-page"
export default class extends Controller {
  static targets = ["quizSection", "signatureSection", "launchButtonContainer"]

  showQuiz() {
    // Affiche la section du quiz
    this.quizSectionTarget.classList.remove('d-none')
    // Masque le bouton "Lancer le Quiz"
    this.launchButtonContainerTarget.classList.add('d-none')
  }

  handleQuizSuccess() {
    // Masque la section du quiz
    this.quizSectionTarget.classList.add('d-none')

    // Affiche la section de signature
    this.signatureSectionTarget.classList.remove('d-none')
    this.signatureSectionTarget.scrollIntoView({ behavior: 'smooth' })
  }
}