# frozen_string_literal: true

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    TransactionGuard.configure { |config| config.mode = :raise }
  end

  test "creating a user is rejected when after_create has side effects" do
    post users_url, params: { name: "Yashika" }

    assert_response :unprocessable_entity
    assert_match(/External side effect detected/, response.parsed_body["error"])
  end

  test "creating a user succeeds when mode is off" do
    TransactionGuard.configure { |config| config.mode = :off }

    assert_difference("User.count", 1) do
      post users_url, params: { name: "Yashika" }
    end

    assert_response :created
  end
end
