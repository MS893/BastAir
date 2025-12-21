import { Controller } from "@hotwired/stimulus"

// Se connecte à data-controller="user-form"
export default class extends Controller {
  static targets = ["instructorToggle", "instructorField"]

  connect() {
    this.toggleInstructorFields()
  }

  toggleInstructorFields() {
    const isInstructor = this.instructorToggleTarget.checked
    this.instructorFieldTargets.forEach(field => {
      field.style.display = isInstructor ? "" : "none"
    })
  }
  
}
