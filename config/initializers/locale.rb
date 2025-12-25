# frozen_string_literal: true

# Définit la langue par défaut de l'application sur le français.
# Cela garantit que Rails cherchera les traductions dans fr.yml en premier.

Rails.application.config.i18n.default_locale = :fr
