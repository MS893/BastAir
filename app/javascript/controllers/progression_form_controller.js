import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="progression-form"
export default class extends Controller {

  submitForm(event) {
    event.target.form.requestSubmit();
  }
  
}
