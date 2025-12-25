# frozen_string_literal: true

module UsersAuth
  class PasswordsController < Devise::PasswordsController
    prepend_before_action :check_captcha, only: [:create]

    # POST /resource/password
    def create
      self.resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?

      if successfully_sent?(resource)
        respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
      else
        flash[:alert] = resource.errors.full_messages.join(', ')
        redirect_to new_user_password_path
      end
    end

    private

    def check_captcha
      return if verify_recaptcha

      redirect_to new_user_password_path
    end
  end
end
