# frozen_string_literal: true

class CustomFailure < Devise::FailureApp
  def default_url_options
    { locale: I18n.locale }
  end
end
