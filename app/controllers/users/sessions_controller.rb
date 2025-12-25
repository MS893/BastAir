# frozen_string_literal: true

# app/controllers/users/sessions_controller.rb
module Users
  class SessionsController < Devise::SessionsController
    prepend_before_action :check_captcha, only: [:create]

    private

    def check_captcha
      return if verify_recaptcha

      self.resource = resource_class.new
      respond_with_navigational(resource) { render :new }
    end
  end
end
