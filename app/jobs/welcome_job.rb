# frozen_string_literal: true

class WelcomeJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    User.find_by(id: user_id)
  end
end
