# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    prepend_before_action :check_captcha, only: [:create] # Vérifie le captcha avant la création
    before_action :configure_sign_up_params, only: [:create]

    def create
      super
    end

    # redirige l'utilisateur vers la page d'édition de son profil après l'inscription
    def after_sign_up_path_for(resource)
      edit_user_path(resource)
    end

    protected

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])
    end

    private

    # vérification cptacha Google (je ne suis pas un robot)
    def check_captcha
      return if verify_recaptcha

      self.resource = resource_class.new sign_up_params
      respond_with_navigational(resource) { render :new }
    end
  end
end
