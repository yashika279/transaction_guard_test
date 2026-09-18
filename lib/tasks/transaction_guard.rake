# frozen_string_literal: true

namespace :transaction_guard do
  desc "Demonstrate TransactionGuard detecting side effects inside a transaction"
  task demo: :environment do
    puts "TransactionGuard mode: #{TransactionGuard.configuration.mode}"
    puts

    run_demo("HTTP request") do
      http = Net::HTTP.new("example.com", 80)
      http.define_singleton_method(:request) do |*|
        Struct.new(:code).new("200")
      end
      http.get("/")
    end

    run_demo("email delivery") do
      WelcomeMailer.welcome(User.new(name: "Demo")).deliver_now
    end

    run_demo("job enqueue") do
      WelcomeJob.perform_later(1)
    end
  end
end

def run_demo(label)
  puts "== #{label} inside User.transaction =="
  User.transaction do
    User.create!(name: "Demo")
    yield
  end
  puts
rescue TransactionGuard::Error => error
  puts error.message
  puts
end
