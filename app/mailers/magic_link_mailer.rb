class MagicLinkMailer < ApplicationMailer
  def login(user, token)
    @login_url = Rails.application.routes.url_helpers.api_auth_magic_link_url(
      token: token,
      **default_url_options
    )

    mail(to: user.email, subject: "Your Notebook Calendar login link")
  end
end
