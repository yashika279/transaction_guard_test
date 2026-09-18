# TransactionGuard test app

Rails 8 sandbox for exercising the local `transaction_guard` gem.

## Setup

```bash
bundle install
bin/rails db:prepare
```

The gem is loaded from the sibling path:

```ruby
gem "transaction_guard", path: "../transaction_guard"
```

## Demo

Warn mode (default in development/test):

```bash
bin/rails transaction_guard:demo
```

Raise mode:

```bash
bin/rails runner 'TransactionGuard.configure { |c| c.mode = :raise }; load Rails.root.join("lib/tasks/transaction_guard.rake"); Rake::Task["transaction_guard:demo"].invoke'
```

Or set `config.mode = :raise` in `config/initializers/transaction_guard.rb` and run the demo task.

## Tests

```bash
bin/rails test test/transaction_guard_test.rb
```

These tests assert that HTTP, email, and ActiveJob side effects inside a transaction raise `TransactionGuard::Error` when mode is `:raise`.
