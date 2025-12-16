import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quiz-modal"
export default class extends Controller {
  static targets = ["question", "validateButton"]
  static outlets = ["quiz-page"] // L'outlet reste nécessaire pour communiquer

  checkAnswers() {
    const totalQuestions = this.questionTargets.length;
    let answeredQuestions = 0;
    let correctAnswers = 0;

    this.questionTargets.forEach(question => {
      const selectedAnswer = question.querySelector('input[type="radio"]:checked');

      if (selectedAnswer) {
        answeredQuestions++;
        if (selectedAnswer.dataset.correct === "true") {
          correctAnswers++;
        }
      }
    });

    if (answeredQuestions === totalQuestions && correctAnswers === totalQuestions) {
      this.showValidateButton();
    } else {
      this.hideValidateButton();
    }
  }

  showValidateButton() {
    this.validateButtonTarget.classList.remove('d-none');
  }

  hideValidateButton() {
    this.validateButtonTarget.classList.add('d-none');
  }

  validate() {
    // Appelle la méthode sur le contrôleur "outlet"
    if (this.hasQuizPageOutlet) {
      this.quizPageOutlet.handleQuizSuccess()
    }
  }
}