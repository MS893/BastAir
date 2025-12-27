
---

# 📚 Architecture Messagerie Rails : Temps Réel, Vocal & STT

Ce document résume les stratégies et outils recommandés pour mettre en place une messagerie moderne (type chat) avec support vocal et transcription automatique.

---

## 🏗️ 1. Architecture de Base (Le "Moteur")

Pour une application moderne, nous évitons les anciennes gems comme *Mailboxer* au profit d'une solution native plus flexible utilisant **Hotwire**.

### Modèles de données recommandés

* **Conversation** : `has_many :messages`, `has_many :users, through: :participants`
* **Message** : `belongs_to :user`, `belongs_to :conversation`, `body:text`.
* **Participant** : Table de jointure entre `User` et `Conversation`.

### Technologies Core

* **Action Cable** : Pour la communication WebSocket (fondation du temps réel).
* **Turbo Streams** : Pour injecter les nouveaux messages dans la page de l'interlocuteur sans recharger.

---

## 🎙️ 2. Gestion du Vocal (Audio)

Pour permettre l'envoi de notes vocales, la structure repose sur le stockage de fichiers.

### Outils nécessaires

* **Active Storage** : Indispensable pour lier un fichier audio au modèle `Message`.
* **MediaRecorder API** : API JavaScript native pour capturer le son du micro.

### Exemple de configuration du modèle

```ruby
class Message < ApplicationRecord
  belongs_to :user
  has_one_attached :voice_note # Permet de stocker le fichier audio
  
  # Diffusion automatique en temps réel
  after_create_commit { broadcast_append_to self.conversation }
end

```

---

## ✍️ 3. Speech-to-Text (STT) : La Dictée Vocale

Au lieu d'envoyer un fichier audio, on transforme la voix en texte directement dans le champ de saisie.

### Solution A : Web Speech API (Gratuit & Navigateur)

C'est la solution la plus simple. Le traitement se fait côté client.

* **Avantages** : Gratuit, instantané, pas de charge serveur.
* **Inconvénients** : Dépend du navigateur (très bon sur Chrome/Safari), moins précis avec l'accent ou le bruit.

### Solution B : OpenAI Whisper (Premium & Précis)

On envoie l'audio au serveur, puis à une API.

* **Processus** :
1. Enregistrement audio.
2. Envoi du fichier à Rails via `Active Storage`.
3. Un job en arrière-plan (`Sidekiq`) envoie le fichier à l'API OpenAI Whisper.
4. Le texte transcrit est renvoyé à l'utilisateur via `Turbo Streams`.



---

## 🛠️ 4. Implémentation du Bouton de Dictée (Stimulus)

Voici le code pour un bouton "Micro" qui remplit automatiquement votre formulaire.

**Fichier : `app/javascript/controllers/speech_to_text_controller.js**`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "status" ]

  connect() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (SpeechRecognition) {
      this.recognition = new SpeechRecognition()
      this.recognition.lang = 'fr-FR'
      this.recognition.continuous = false

      this.recognition.onresult = (event) => {
        const transcript = event.results[0][0].transcript
        this.inputTarget.value += " " + transcript
        this.statusTarget.textContent = ""
      }
      
      this.recognition.onerror = () => {
        this.statusTarget.textContent = "Erreur de capture..."
      }
    }
  }

  start() {
    this.statusTarget.textContent = "Écoute en cours..."
    this.recognition.start()
  }
}

```

**Fichier : `app/views/messages/_form.html.erb**`

```html
<div data-controller="speech-to-text">
  <%= form_with(model: [@conversation, @message]) do |f| %>
    <%= f.text_area :body, data: { speech_to_text_target: "input" } %>
    
    <button type="button" data-action="click->speech-to-text#start">
      🎤 Dictée vocale
    </button>
    
    <span data-speech-to-text_target="status"></span>
    <%= f.submit "Envoyer" %>
  <% end %>
</div>

```

---

## 📋 5. Check-list des Gems à installer

| Nom | Usage |
| --- | --- |
| `redis` | Requis pour Action Cable en production. |
| `image_processing` | Utile pour analyser les métadonnées des fichiers audio. |
| `sidekiq` | (Optionnel) Pour traiter les transcriptions lourdes en arrière-plan. |
| `ruby-openai` | (Optionnel) Si vous choisissez la transcription via Whisper. |

---
