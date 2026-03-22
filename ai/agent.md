# AI Coding Agent — AULABS

## Identity

You are an AI coding agent working on AULABS, a Rails 8.1 automotive services platform. You implement tasks from `ai/tasks.md` following the architecture in `ai/architecture.md` and patterns in `ai/patterns/`.

---

## Rules

1. **Always follow `ai/architecture.md`.** It is the single source of truth for domain boundaries, authorization, data flow, and namespace separation.
2. **Always follow `ai/patterns/*`.** Every pattern file defines Do/Don't examples and anti-patterns. Treat anti-patterns as hard errors.
3. **Do not invent new patterns.** If a situation is not covered by existing patterns, implement the simplest Rails-conventional solution. Do not create new abstractions, service objects, or design patterns.
4. **One User model.** Driver is the default role. There is no Operator model — workshop access comes from `WorkshopOperator` join table.
5. **Admin is a separate Devise model.** Never conflate `User` and `Admin`.
6. **UI text is in Ukrainian.** All user-facing strings must have entries in both `uk.yml` and `en.yml`.
7. **Minitest, not RSpec.** All tests use `ActiveSupport::TestCase` and fixtures.

---

## Workflow

For every task:

### 1. Read the task
- Open `ai/tasks.md`, find the task by number.
- Read the description, files, and acceptance criteria completely.

### 2. Identify affected files
- List every file the task specifies.
- Check if those files already exist. If they do, read them before making changes.

### 3. Check patterns
- Before writing any code, read the relevant pattern files:
  - Writing a model? → `ai/patterns/models.md`
  - Writing a controller? → `ai/patterns/controllers.md`
  - Adding authorization? → `ai/patterns/authorization.md`
  - Creating ServiceRequest/ServiceRecord? → `ai/patterns/service_requests.md`
  - Writing a migration? → `ai/patterns/data_integrity.md`
- Follow the Do examples. Avoid the Don't examples.

### 4. Implement the minimal solution
- Write only what the task requires. No extra features, no extra refactoring.
- Follow Rails conventions and the project's existing code style:
  - Double quotes for strings
  - 2-space indentation
  - Guard clauses for early returns
  - `frozen_string_literal: true` in migrations

### 5. Add tests
- Every model gets a test file in `test/models/`.
- Every controller gets a test file in `test/controllers/`.
- Use fixtures from `test/fixtures/*.yml`.
- Test names are descriptive: `test "workshop defaults to pending status"`.

### 6. Self-review
Before considering the task done, verify:
- [ ] Migration has `foreign_key: true` on all references
- [ ] Migration has `null: false` on required columns
- [ ] Enums use explicit integer hash form, not arrays
- [ ] Scopes use lambdas
- [ ] Controller queries are scoped to the authenticated principal
- [ ] No business logic in controllers
- [ ] Status transitions use optimistic locking where required
- [ ] `bin/rubocop` passes with zero offenses
- [ ] `bin/rails test` passes for affected test files
- [ ] No new patterns were invented

---

## Constraints

### Do
- Keep code simple and readable
- Follow Rails conventions
- Use fat models, thin controllers
- Use `find_by` over `where(...).first`
- Use `before_action` for shared setup
- Rescue specific errors, not generic ones
- Use transactions for multi-record atomic operations
- **Always use `t()` locale helpers in views** — never hardcode user-facing strings. Add keys to both `config/locales/en.yml` and `config/locales/uk.yml`.

### Don't
- Create service objects, form objects, or interactors
- Add features not specified in the task
- Add comments unless the logic is non-obvious
- Add type annotations or docstrings to unchanged code
- Use `default_scope`
- Use `update_columns` on append-only records
- Check `user.role` for workshop access — use `WorkshopOperator`
- Store `current_user` in models
- Use `params.permit!` or skip strong parameters
- Hardcode user-facing strings in views — always use `t()` with locale keys in both `en.yml` and `uk.yml`

---

## File Conventions

| Type | Location | Naming |
|---|---|---|
| Models | `app/models/` | `workshop_operator.rb` |
| Controllers | `app/controllers/` | `workshops_controller.rb` |
| Admin controllers | `app/controllers/admin/` | `admin/workshops_controller.rb` |
| WM controllers | `app/controllers/workshop_management/` | `workshop_management/service_requests_controller.rb` |
| Views | `app/views/<controller>/` | `index.html.erb` |
| Migrations | `db/migrate/` | `YYYYMMDDHHMMSS_create_cars.rb` |
| Tests | `test/models/`, `test/controllers/` | `car_test.rb`, `cars_controller_test.rb` |
| Fixtures | `test/fixtures/` | `cars.yml` |
| Jobs | `app/jobs/` | `expire_car_transfers_job.rb` |

---

## Task Dependencies

Tasks must be implemented in order within each phase. Phases with no cross-dependencies can run in parallel. See the dependency graph in `ai/tasks.md`.

Never skip a task. Never combine tasks. One task = one unit of work.