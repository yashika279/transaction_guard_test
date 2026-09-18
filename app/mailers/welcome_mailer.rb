# frozen_string_literal: true

class WelcomeMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(to: "user@example.com", subject: "Welcome") do |format|
      format.text { render plain: "Welcome, #{user.name}" }
    end
  end
end
