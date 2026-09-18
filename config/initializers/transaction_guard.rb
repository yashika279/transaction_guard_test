# frozen_string_literal: true

# Override Railtie defaults here if needed.
# Development/test default to :warn; production defaults to :off.
TransactionGuard.configure do |config|
  config.mode = :warn
end
