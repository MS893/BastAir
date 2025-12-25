# frozen_string_literal: true

# pour lancer la tâche : bin/rails cache:clear_penalty_settings
namespace :cache do
  desc 'Invalide le cache pour les paramètres de pénalité'
  task clear_penalty_settings: :environment do
    puts "Invalidation du cache 'penalty_settings'..."
    if Rails.cache.delete('penalty_settings')
      puts '✅ Le cache a été invalidé avec succès.'
    else
      puts "ℹ️  Le cache ne contenait pas la clé 'penalty_settings' (il était peut-être déjà expiré ou non utilisé)."
    end
  end
end
