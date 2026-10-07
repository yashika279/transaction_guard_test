# TransactionGuard test app

Rails 8 app wired like a normal app using [`transaction_guard`](https://github.com/yashika279/transaction_guard).

## Setup

```bash
bundle install
bin/rails db:prepare
```

Gem (local sibling, or GitHub on CI):

```ruby
gem "transaction_guard", path: "../transaction_guard"
```

## Real-app wiring

| Piece | Role |
|-------|------|
| `config/initializers/transaction_guard.rb` | Modes: `:warn` (dev), `:raise` (test), `:off` (prod) |
| `app/models/user.rb` | `after_create` sends job + email (unsafe pattern TG detects) |
| `POST /users` | Normal request path that hits that callback |

TransactionGuard is **runtime-only** — no whole-repo scan. You see it when that code runs (console, request, or tests).

## Try it like a real app

**Console (development = `:warn`):**

```bash
bin/rails console
```

```ruby
User.create!(name: "Yashika")
# => warning on stderr; user is still created

TransactionGuard.configure { |c| c.mode = :raise }
User.create!(name: "Strict")
# => TransactionGuard::Error

TransactionGuard.configure { |c| c.mode = :off }
User.create!(name: "Silent")
# => no warning, no error
```

**HTTP request (start the server first):**

```bash
bin/rails server
```

```bash
curl -X POST http://localhost:3000/users -d "name=Yashika"
```

Watch the server log for TransactionGuard warnings (`:warn` in development).

## Tests & CI

```bash
bin/rails test test/transaction_guard_test.rb test/controllers/users_controller_test.rb
bin/rails test   # whole suite
bin/ci           # style + security + tests
```

GitHub Actions already runs `bin/rails test` on push/PR.
