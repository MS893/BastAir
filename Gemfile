source "https://rubygems.org"

gem "faker"
gem 'simple_form'
# Gem pour la pagination de la page index si beaucoup d'infos à afficher
gem 'kaminari'
# Preview email in the default browser instead of sending it
gem "letter_opener_web", group: :development
# pour ne pas envoyer les identifiants à Github
gem "dotenv-rails"
# système d'authentification complet
gem "devise"
# paiement en ligne
gem "stripe"
# chargement d'images
gem "image_processing", ">= 1.2"
# Active Storage pour le chargement de fichiers
gem "activestorage"
gem 'active_storage_validations'
# exportation au format pdf
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
# ajout captcha Google
gem 'recaptcha', require: 'recaptcha/rails'
# gestion des tâches automatiques
gem 'whenever', require: false
# APIs Google
gem 'googleauth'
gem 'google-apis-calendar_v3', '~> 0.5.0'
gem 'google-apis-drive_v3', '~> 0.5.0'
# graphiques pour la compta
gem 'chartkick'
gem 'rails-i18n'
# export fichier csv
gem 'csv' 
# Pour le rendu des fichiers Markdown
gem 'redcarpet'





# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # letter_opener intercepte l'email envoyé et l'ouvre dans un nouvel onglet du navigateur
  gem 'letter_opener'

  # Rspec pour les tests
  gem "rspec-rails", "~> 6.1"

end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
