# frozen_string_literal: true

require "test_helper"
require "net/http"

class TransactionGuardTest < ActiveSupport::TestCase
  setup do
    TransactionGuard.configure { |config| config.mode = :raise }
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    TransactionGuard.configure { |config| config.mode = :warn }
  end

  test "raises when Net::HTTP is used inside a transaction" do
    http = Net::HTTP.new("example.com", 80)
    http.define_singleton_method(:request) do |*|
      Struct.new(:code).new("200")
    end

    assert_raises(TransactionGuard::Error) do
      User.transaction do
        User.create!(name: "HTTP user")
        http.get("/")
      end
    end
  end

  test "raises when email is delivered inside a transaction" do
    assert_raises(TransactionGuard::Error) do
      User.transaction do
        user = User.create!(name: "Mail user")
        WelcomeMailer.welcome(user).deliver_now
      end
    end
  end

  test "raises when a job is enqueued inside a transaction" do
    assert_raises(TransactionGuard::Error) do
      User.transaction do
        user = User.create!(name: "Job user")
        WelcomeJob.perform_later(user.id)
      end
    end
  end

  test "does not raise outside a transaction" do
    assert_nothing_raised do
      user = User.create!(name: "Safe user")
      WelcomeJob.perform_later(user.id)
    end
  end
end
