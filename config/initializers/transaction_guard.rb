# frozen_string_literal: true

# Real-app defaults:
# - development: :warn  (see issues in logs while coding)
# - test:        :raise (fail CI when side effects run inside transactions)
# - production:  :off   (detection disabled)
TransactionGuard.configure do |config|
  config.mode =
    if Rails.env.production?
      :off
    elsif Rails.env.test?
      :raise
    else
      :warn
    end
end
