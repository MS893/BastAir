# frozen_string_literal: true

module UsersAuth
  class SessionsController < Devise::SessionsController
    # POST /resource/sign_in
    prepend_before_action :check_captcha, only: [:create]

    def create
      self.resource = warden.authenticate(auth_options)
      if resource
        set_flash_message!(:notice, :signed_in)
        sign_in(resource_name, resource)
        yield resource if block_given?
        respond_with resource, location: after_sign_in_path_for(resource)
      else
        # En cas d'échec, on utilise un flash et on redirige.
        # Cela force un rechargement complet de la page et des scripts.
        flash[:alert] = 'Adresse e-mail ou mot de passe invalide.'
        redirect_to new_user_session_path
      end
    end

    private

    def check_captcha
      # Ne vérifie le captcha qu'en environnement de production
      return if Rails.env.local?

      return if verify_recaptcha

      self.resource = resource_class.new
      resource.validate # Look for any other validation errors besides reCAPTCHA
      set_flash_message!(:alert, :recaptcha_error)
      respond_with_navigational(resource) { render :new }
    end
  end
end
