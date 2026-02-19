# AGENTS.md - Klaxon Development Guide

Klaxon is a Ruby on Rails 8 application for AULABS. It uses PostgreSQL, TailwindCSS 4, Hotwire (Turbo/Stimulus) via import maps, Devise for authentication, and OmniAuth for OAuth. UI text is in Ukrainian.

## Tech Stack

Ruby 3.x, Rails 8.1.x, PostgreSQL, Propshaft, TailwindCSS 4.x, Import maps (Turbo + Stimulus, no Node/npm), Devise + OmniAuth, Minitest + Capybara/Selenium, RuboCop (Rails Omakase).

## Commands

### Running Tests

```bash
bin/rails test                             # all unit/integration tests
bin/rails test test/models/user_test.rb    # single test file
bin/rails test test/models/user_test.rb:10 # single test by line number
bin/rails test:system                      # system tests (Capybara/Selenium)
bin/rails db:test:prepare                  # reset test DB schema
```

### Linting & Security

```bash
bin/rubocop                # lint (must pass with zero offenses)
bin/rubocop -a             # auto-fix safe cops
bin/brakeman --no-pager    # static security analysis
bin/bundler-audit           # gem vulnerability check
bin/importmap audit         # JS dependency audit
```

### Setup & Database

```bash
bundle install && bin/rails db:create db:migrate  # initial setup
bin/dev                    # starts Rails server + TailwindCSS watcher
bin/rails db:reset         # drop + create + migrate + seed
```

## CI Pipeline

CI (`.github/workflows/ci.yml`) runs on every PR/push to `main`: scan_ruby (Brakeman + bundler-audit), scan_js (importmap audit), lint (RuboCop), test, system-test. All must pass.

## Code Style Guidelines

Uses **Rails Omakase** RuboCop rules (`.rubocop.yml` inherits `rubocop-rails-omakase`).

### Formatting

- 2-space indentation, no tabs
- Double quotes for strings (Omakase default)
- Lines under 100 characters when practical
- `frozen_string_literal: true` in migrations (follow existing patterns)

### Naming Conventions

| Type             | Convention          | Example                    |
|------------------|---------------------|----------------------------|
| Models           | Singular PascalCase | `User`, `PageScan`         |
| Controllers      | Plural PascalCase   | `UsersController`          |
| DB tables        | Plural snake_case   | `users`, `page_scans`      |
| Methods          | snake_case          | `perform_scan`             |
| Boolean methods  | End with `?`        | `valid_url?`, `confirmed?` |
| Constants        | SCREAMING_SNAKE     | `MAX_RETRIES`              |

### Methods & Error Handling

```ruby
# Guard clauses for early returns
def valid_url?(url)
  return false if url.blank?
  uri = URI.parse(url)
  uri.scheme&.in?(["http", "https"])
rescue URI::InvalidURIError
  false
end

# Rescue specific errors, log them
def perform_action
  # ...
rescue SomeSpecificError => e
  Rails.logger.error(e.message)
  nil
end
```

### ActiveRecord

```ruby
scope :active, -> { where(status: "active") }
user = User.find_by(email: "test@example.com")  # not .where(...).first
```

### Controllers

- All controllers inherit from `ApplicationController`
- Authentication is enforced globally: `before_action :authenticate_user!`
- `allow_browser versions: :modern` is set globally

### Views & Frontend

- ERB templates with TailwindCSS utility classes
- Custom form builder `AuFormBuilder` (`app/form_builders/`) handles styled inputs and error display
- Flash messages render as fixed bottom-right toasts
- **UI text is in Ukrainian — preserve this convention**
- TailwindCSS source: `app/assets/tailwind/application.css`
- Custom theme color: `--color-brand-black: #000000`
- Component classes: `.btn-primary` (black button), `.label-input` (uppercase label)

### JavaScript

- Import maps only — pins in `config/importmap.rb`
- Stimulus controllers in `app/javascript/controllers/`
- No npm/yarn/Node.js

### Testing

```ruby
class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)  # fixtures loaded via `fixtures :all`
  end

  test "descriptive test name" do
    assert @user.valid?
  end
end
```

- Tests run in parallel (`parallelize(workers: :number_of_processors)`)
- Fixtures in `test/fixtures/*.yml`
- System tests use headless Chrome at 1400x1400

## Project Structure

```
app/
  controllers/     # ApplicationController requires auth globally
  form_builders/   # AuFormBuilder (TailwindCSS form builder)
  models/          # ActiveRecord models (User with Devise)
  views/           # ERB templates; devise/ views are customized
  jobs/            # ActiveJob (backed by SolidQueue)
  assets/tailwind/ # TailwindCSS source with custom theme
config/
  routes.rb        # Devise routes + root "dashboard#index"
  importmap.rb     # JS dependency pins
db/migrate/        # Database migrations
test/
  models/          # Model tests
  controllers/     # Controller tests
  system/          # System tests (Capybara)
  fixtures/        # YAML test fixtures
```

## Pre-Commit Checklist

1. `bin/rubocop` passes with zero offenses
2. `bin/rails test` passes
3. `bin/brakeman --no-pager` reports no warnings
4. `bin/bundler-audit` reports no vulnerabilities
