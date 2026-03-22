# AGENTS.md - AULABS Development Guide

## Product Vision

**AULABS** is a FAANG-quality platform for automotive services. Think of it as the intersection of Google Maps, Booking.com, and a real-time queue management system — purpose-built for the car service industry, built for global scale.

> Note: `klaxon` is the name of this repository. The product is **AULABS**.

### What We're Building

Drivers waste enormous time at car services: waiting in unknown queues at tire shops during seasonal rushes, circling parking lots, sitting in line at car washes, not knowing if an evacuator is nearby. AULABS eliminates this friction.

**For drivers**, AULABS is a single app to:
- Find nearby car service workshops by type and see live availability
- Join a queue remotely — arrive when it's your turn, not an hour before
- Book a time slot for planned services
- Track estimated wait time in real time
- Get notified when to head over

**For service businesses** (workshops, parking lots, car washes, detailing studios), AULABS is an operations platform to:
- Manage queues and appointments digitally
- Reduce walk-away customers who leave when they see a long wait
- Show real-time capacity to drivers in the area
- Build a verified reputation with reviews and ratings

### Car Service History

Every car in the system has a full, persistent service history — a logbook of everything that has ever been done to it across any workshop on the platform.

**For drivers**: one place to see everything done to their car — oil changes, tire swaps, diagnostics, detailing — regardless of which workshop performed the service. No more lost paper receipts or forgotten maintenance intervals.

**For workshops** (with driver permission): access to a car's history before starting work. A mechanic can see that the car had diagnostics 2 months ago, tires changed last winter, and that the previous STO flagged a brake issue. This enables better, safer service.

Key principles:
- A **Car** belongs to a User (driver); a driver may have multiple cars
- Service history entries (**ServiceRecord**) are created by workshops when a job is completed
- Drivers control visibility — a driver can grant or revoke a workshop's access to their car's history
- History is append-only — records are never deleted, only the car owner can see the full log
- This data is a core product differentiator: over time, AULABS becomes the trusted digital passport for every car

### Service Categories

The platform covers the full lifecycle of car ownership needs:

| Category | Ukrainian | Key Feature |
|---|---|---|
| Auto repair (STO) | СТО | appointment booking + queue |
| Tire service | Шиномонтаж | seasonal surge queue management |
| Car wash | Автомийка | live slot availability |
| Detailing | Детейлінг | multi-hour appointment scheduling |
| Evacuator / Towing | Евакуатор | on-demand dispatch, live tracking |
| Diagnostics | Діагностика | appointment + result history |
| Parking | Паркінг | real-time space availability |

### Product Quality Bar

We build at FAANG standards:
- **Reliability**: queues and slot state must be consistent — no double-bookings, no lost updates
- **Real-time UX**: drivers see live queue position and wait estimates via Hotwire/Turbo Streams
- **Speed**: every page interaction must feel instant; background jobs via SolidQueue handle async work
- **Trust**: reviews, ratings, verified business profiles — every feature must reinforce driver confidence
- **Simplicity**: a driver finding a tire shop at 8am during a snowstorm must complete the flow in under 60 seconds

### Domain Vocabulary

Always use these terms consistently in code, UI, and discussions:

- **User** — the single user model for all people in the system; roles determine what they can do
- **Driver** — a User role; a car owner who finds workshops and joins queues
- **Operator** — a business owner/staff who manages a workshop
- **Workshop** — a service business (STO, car wash, etc.)
- **ServiceCategory** — the type of service a workshop provides
- **Queue / Черга** — a live, real-time line a driver joins remotely
- **Slot / Слот** — a booked time window for a planned appointment
- **WorkingHour** — when a workshop is open each day of the week

> There is **one `User` model**. Driver is role, not separate models. Always think in terms of `user.role` or similar, never separate tables.

---

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
