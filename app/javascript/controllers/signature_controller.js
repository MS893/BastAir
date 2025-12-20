import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "input"]
  static values = { signerName: String }

  connect() {
    this.canvas = this.canvasTarget
    this.ctx = this.canvas.getContext("2d")
    
    // Configuration du style de trait
    this.ctx.lineWidth = 2
    this.ctx.lineJoin = "round"
    this.ctx.lineCap = "round"
    this.ctx.strokeStyle = "#000000"

    this.isDrawing = false
    this.hasDrawn = false

    // Ajout des écouteurs d'événements pour la souris et le tactile
    this.canvas.addEventListener("mousedown", this.startDrawing.bind(this))
    this.canvas.addEventListener("mousemove", this.draw.bind(this))
    this.canvas.addEventListener("mouseup", this.stopDrawing.bind(this))
    this.canvas.addEventListener("mouseout", this.stopDrawing.bind(this))
    
    this.canvas.addEventListener("touchstart", this.startDrawing.bind(this))
    this.canvas.addEventListener("touchmove", this.draw.bind(this))
    this.canvas.addEventListener("touchend", this.stopDrawing.bind(this))
  }

  startDrawing(event) {
    this.isDrawing = true
    this.ctx.beginPath()
    const { x, y } = this.getCoordinates(event)
    this.ctx.moveTo(x, y)
    event.preventDefault() // Empêche le scroll sur mobile
  }

  draw(event) {
    if (!this.isDrawing) return
    const { x, y } = this.getCoordinates(event)
    this.ctx.lineTo(x, y)
    this.ctx.stroke()
    this.hasDrawn = true
    event.preventDefault()
  }

  stopDrawing() {
    this.isDrawing = false
  }

  getCoordinates(event) {
    const rect = this.canvas.getBoundingClientRect()
    let clientX, clientY

    if (event.touches && event.touches.length > 0) {
      clientX = event.touches[0].clientX
      clientY = event.touches[0].clientY
    } else {
      clientX = event.clientX
      clientY = event.clientY
    }

    return {
      x: clientX - rect.left,
      y: clientY - rect.top
    }
  }

  clear() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    this.inputTarget.value = ""
    this.hasDrawn = false
  }

  submit(event) {
    if (!this.hasDrawn) {
      event.preventDefault()
      alert("Veuillez signer dans la zone prévue avant de valider.")
      return
    }
    
    // Création d'un canvas temporaire pour redimensionner l'image (réduction de 50%)
    // pour économiser de l'espace de stockage
    const scaledCanvas = document.createElement('canvas')
    scaledCanvas.width = this.canvas.width * 0.5
    scaledCanvas.height = this.canvas.height * 0.5
    
    const scaledCtx = scaledCanvas.getContext('2d')
    scaledCtx.drawImage(this.canvas, 0, 0, scaledCanvas.width, scaledCanvas.height)

    // On met à jour le champ caché avec l'image redimensionnée
    this.inputTarget.value = scaledCanvas.toDataURL("image/png")
  }
}