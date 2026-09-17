class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "no-reply@#{ENV.fetch("APP_HOST", "localhost")}") }
  layout "mailer"
end
