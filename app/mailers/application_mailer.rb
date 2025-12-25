# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('FREE_EMAIL_USER', nil)
  #  default from: "no-reply@monsite.fr"
  layout 'mailer'
end
