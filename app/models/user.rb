# frozen_string_literal: true

class User < ApplicationRecord
  # Unsafe in a real app: after_create still runs inside create!'s DB transaction.
  # If that transaction rolls back, the job/email cannot be rolled back with it.
  # Prefer: after_commit :send_welcome_email, on: :create
  after_create :send_welcome_email

  private

  def send_welcome_email
    WelcomeJob.perform_later(id)
    WelcomeMailer.welcome(self).deliver_now
  end
end
