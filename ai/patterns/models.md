# Pattern: Models

## Rules

1. **One User model.** Driver and future roles are `role` enum values on `User`. Never create a separate Operator model.
2. **Admin is a separate Devise model** (`Admin < ApplicationRecord`). It is never a `User`.
3. **Enums use integer columns with explicit values.** Always define the hash form: `enum :status, { pending: 0, active: 1 }`. Never rely on positional array enums.
4. **Scopes are lambdas.** `scope :active, -> { where(status: :active) }`. No scope without `->`.
5. **Validations belong in the model.** Cross-model consistency checks (e.g., `car_belongs_to_current_user`) are model validations, not controller logic.
6. **`before_create` for immutable snapshots.** Price snapshotting and `completed_at` defaulting happen in `before_create` or `before_validation`. Never in the controller.
7. **`after_create` for side effects.** `update_car_odometer`, `recompute_wait_estimates` — these are model callbacks, not controller steps.
8. **Append-only models have no `updated_at`.** `CarTransferEvent` and any future audit log models must not include `updated_at`.
9. **`belongs_to` is required by default.** Only use `optional: true` when the foreign key is genuinely nullable in the schema (e.g., `Queue#service_category_id`, `Car#vin`).
10. **No random service objects.** If business logic fits in a model method or callback, put it there. Extract only when the logic spans 3+ models and has no natural owner.
11. **`find_by` over `where(...).first`.** `User.find_by(email: ...)` not `User.where(email: ...).first`.
12. **Guard clauses for early returns in methods.**

---

## Do / Don't

### Enums

```ruby
# DO
enum :status, { pending: 0, active: 1, declined: 2, suspended: 3 }

# DON'T
enum status: [:pending, :active, :declined, :suspended]  # positional — breaks on reorder
```

### Scopes

```ruby
# DO
scope :active, -> { where(status: :active) }
scope :today, -> { where(date: Date.current) }

# DON'T
scope :active, where(status: :active)  # not a lambda — evaluated at load time
def self.active; where(status: :active); end  # fine, but use scope for simple cases
```

### Validations in model, not controller

```ruby
# DO — model validates its own consistency
class ServiceRequest < ApplicationRecord
  validate :service_offered_by_workshop

  private

  def service_offered_by_workshop
    return unless workshop_service_category
    if workshop_service_category.workshop_id != workshop_id
      errors.add(:workshop_service_category, "does not belong to this workshop")
    end
  end
end

# DON'T — controller doing model work
def create
  if @service_request.workshop_service_category.workshop_id != @workshop.id
    redirect_to ..., alert: "Invalid"
  end
end
```

### Before_create snapshot (immutable data)

```ruby
# DO
before_create :snapshot_price

def snapshot_price
  return unless workshop_service_category
  self.price_snapshot = {
    min: workshop_service_category.price_min,
    max: workshop_service_category.price_max,
    unit: workshop_service_category.price_unit,
    currency: workshop_service_category.currency
  }.compact
end

# DON'T — mutate snapshot fields in controller or after save
def create
  @request.price_snapshot = { min: wsc.price_min }  # wrong place
  @request.save
end
```

### Append-only models

```ruby
# DO — migration for CarTransferEvent
create_table :car_transfer_events do |t|
  t.references :car_transfer, null: false, foreign_key: true
  t.references :actor, foreign_key: { to_table: :users }, null: true
  t.integer :event_type, null: false
  t.jsonb :metadata
  t.datetime :created_at, null: false  # only created_at
end

# DON'T
t.timestamps  # adds updated_at, which implies mutability
```

### Association helpers

```ruby
# DO
def manages_workshop?(workshop)
  workshop_operators.exists?(workshop: workshop)
end

def workshop_owner?
  workshop_operators.owner.exists?
end

# DON'T
def manages_workshop?(workshop)
  workshops.include?(workshop)  # loads all workshops into memory
end
```

---

## Anti-Patterns

- **Fat callback chains.** If a model has 5+ callbacks, question whether they all belong there. Prefer explicit methods called from controllers for multi-step flows (like car transfer approval).
- **Using `update_columns` to bypass validations on audit data.** Append-only records must use `create!` only — never update.
- **Global `default_scope`.** Never use `default_scope` — it causes invisible query filters that confuse agents and break admin views.
- **Role-based guards in models.** Models do not check `current_user`. Controllers provide scoped data; models validate data consistency only.
- **Inferring workshop access from `User#role`.** There is no operator role. Access is always from `WorkshopOperator`. Never write `user.role == :operator`.
