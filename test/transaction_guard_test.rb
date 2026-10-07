# frozen_string_literal: true

require "test_helper"
require "net/http"
require "stringio"

class TransactionGuardTest < ActiveSupport::TestCase
  setup do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    # Match config/initializers/transaction_guard.rb for test env
    TransactionGuard.configure { |config| config.mode = :raise }
  end

  # --- Real app path: User after_create ---

  test "raise mode (test default): User.create! raises via after_create side effects" do
    assert_equal :raise, TransactionGuard.configuration.mode

    assert_raises(TransactionGuard::Error) do
      User.create!(name: "Callback user")
    end
  end

  test "warn mode: User.create! warns via after_create and still succeeds" do
    TransactionGuard.configure { |config| config.mode = :warn }

    stderr = capture_stderr do
      assert_difference("User.count", 1) do
        User.create!(name: "Warn callback user")
      end
    end

    assert_match(/External side effect detected/, stderr)
  end

  test "off mode: User.create! is silent" do
    TransactionGuard.configure { |config| config.mode = :off }

    stderr = capture_stderr do
      assert_nothing_raised do
        User.create!(name: "Off callback user")
      end
    end

    assert_no_match(/External side effect detected/, stderr)
  end

  # --- Explicit side effects inside a transaction (no User callback) ---

  test "raise mode: raises for Net::HTTP inside a transaction" do
    assert_raises(TransactionGuard::Error) do
      ActiveRecord::Base.transaction { stubbed_http.get("/") }
    end
  end

  test "raise mode: raises for email delivery inside a transaction" do
    assert_raises(TransactionGuard::Error) do
      ActiveRecord::Base.transaction do
        WelcomeMailer.welcome(User.new(name: "Mail user")).deliver_now
      end
    end
  end

  test "raise mode: raises for job enqueue inside a transaction" do
    assert_raises(TransactionGuard::Error) do
      ActiveRecord::Base.transaction { WelcomeJob.perform_later(1) }
    end
  end

  test "raise mode: does not raise for side effects outside a transaction" do
    assert_nothing_raised do
      WelcomeJob.perform_later(1)
      WelcomeMailer.welcome(User.new(name: "Safe")).deliver_now
    end
  end

  test "warn mode: prints a warning for job enqueue inside a transaction" do
    TransactionGuard.configure { |config| config.mode = :warn }

    stderr = capture_stderr do
      ActiveRecord::Base.transaction { WelcomeJob.perform_later(1) }
    end

    assert_match(/External side effect detected/, stderr)
    assert_match(/Operation:/, stderr)
  end

  test "off mode: does not warn or raise inside a transaction" do
    TransactionGuard.configure { |config| config.mode = :off }

    stderr = capture_stderr do
      assert_nothing_raised do
        ActiveRecord::Base.transaction do
          WelcomeJob.perform_later(1)
          WelcomeMailer.welcome(User.new(name: "Off")).deliver_now
          stubbed_http.get("/")
        end
      end
    end

    assert_no_match(/External side effect detected/, stderr)
  end

  private

  def stubbed_http
    http = Net::HTTP.new("example.com", 80)
    http.define_singleton_method(:request) do |*|
      Struct.new(:code).new("200")
    end
    http
  end

  def capture_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end
end
