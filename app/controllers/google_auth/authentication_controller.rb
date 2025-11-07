class GoogleAuth::AuthenticationController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  # Portée de l'autorisation : nous demandons la permission de lire et écrire sur le calendrier.
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  # Étape 1 : Redirige l'administrateur vers la page de consentement de Google.
  def redirect
    client = Signet::OAuth2::Client.new(client_options)
    # Ligne de débogage : Affiche le client_id dans les logs du serveur Rails.
    puts "DEBUG: Using Google Client ID: #{client.client_id}"

    redirect_to client.authorization_uri.to_s, allow_other_host: true
  end

  # Étape 2 : Google redirige ici après le consentement de l'utilisateur.
  def callback
    client = Signet::OAuth2::Client.new(client_options)
    client.code = params[:code] # Le code d'autorisation fourni par Google

    response = client.fetch_access_token!

    # On sauvegarde les tokens d'accès et de rafraîchissement sur le compte de l'admin.
    current_user.update(
      google_access_token: response['access_token'],
      google_refresh_token: response['refresh_token'],
      google_token_expires_at: Time.now + response['expires_in'].to_i.seconds
    )

    redirect_to root_path, notice: "Votre compte a bien été connecté à Google Calendar."
  end

  private

  def client_options
    {
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      scope: SCOPE,
      redirect_uri: google_auth_callback_url # L'URL de notre action callback
    }
  end
end