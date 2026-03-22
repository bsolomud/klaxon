# Pattern: Data Integrity

## Rules

1. **Foreign key constraints in every migration.** Every `references` column must have `foreign_key: true`. No orphaned records.
2. **Unique indexes at the DB level for uniqueness constraints.** `validates_uniqueness_of` alone is not sufficient — concurrent requests bypass it. Always pair with a DB unique index.
3. **Append-only tables never get `updated_at`.** `CarTransferEvent`, `CarOwnershipRecord` — migrations must not call `t.timestamps`, only `t.datetime :created_at, null: false`.
4. **Partial unique indexes for conditional uniqueness.** One active transfer per car: `add_index :car_transfers, :car_id, unique: true, where: "status = 0"`.
5. **Optimistic locking on all concurrent state machines.** `ServiceRequest` and `QueueEntry` both have `lock_version`. All status transition forms include the hidden `lock_version` field.
6. **`before_create` for immutable data capture.** `snapshot_price` on `ServiceRequest`. Never settable via public API after record creation.
7. **Car odometer is updated via `ServiceRecord#after_create`, not via direct user input.** Drivers cannot set `car.odometer` directly — it is updated when a service record is created.
8. **VIN uniqueness is case-insensitive and enforced at DB level.** `add_index :cars, :vin, unique: true` (store normalized/uppercase).
9. **License plate uniqueness is case-insensitive.** Normalize to uppercase before validation and DB storage.
10. **Queue position is immutable once assigned.** `next_position` is calculated at join time. Never reassign position to fill gaps — mark entries `no_show` or `completed` and leave gaps.
11. **Transactions wrap multi-record atomic operations.** CarTransfer approval, ServiceRecord creation + request completion — always in `ActiveRecord::Base.transaction`.
12. **`null: false` for every required column.** If a column is validated as presence: true in the model, it must be `null: false` in the schema.

---

## Critical Unique Indexes

```ruby
# CarTransfer — one active transfer per car
add_index :car_transfers, :car_id, unique: true, where: "status = 0"

# Queue — one queue per workshop/category/day
add_index :queues, [:workshop_id, :service_category_id, :date], unique: true

# QueueEntry — driver can't join the same queue twice while active
add_index :queue_entries, [:queue_id, :user_id], unique: true,
          where: "status IN (0, 1, 2)"  # waiting, called, in_service

# ServiceRecord — one record per service request
add_index :service_records, :service_request_id, unique: true

# WorkshopServiceCategory — one entry per workshop/category pair
add_index :workshop_service_categories, [:workshop_id, :service_category_id], unique: true

# WorkshopOperator — user can only be linked to a workshop once
add_index :workshop_operators, [:user_id, :workshop_id], unique: true

# Car VIN — if present, must be globally unique
add_index :cars, :vin, unique: true  # combined with model validation: uniqueness, allow_nil: true

# Car license plate — case-insensitive uniqueness enforced at model + index
add_index :cars, "lower(license_plate)", unique: true
```

---

## Do / Don't

### Migrations — foreign keys and null constraints

```ruby
# DO
create_table :service_requests do |t|
  t.references :car, null: false, foreign_key: true
  t.references :workshop, null: false, foreign_key: true
  t.references :workshop_service_category, null: false, foreign_key: true
  t.jsonb :price_snapshot
  t.integer :status, null: false, default: 0
  t.text :description, null: false
  t.datetime :preferred_time, null: false
  t.integer :lock_version, null: false, default: 0
  t.timestamps
end

# DON'T
create_table :service_requests do |t|
  t.integer :car_id           # missing null: false and foreign key
  t.integer :workshop_id
  t.integer :status           # missing default
  t.timestamps
end
```

### Append-only migrations

```ruby
# DO — CarTransferEvent
create_table :car_transfer_events do |t|
  t.references :car_transfer, null: false, foreign_key: true
  t.references :actor, foreign_key: { to_table: :users }, null: true
  t.integer :event_type, null: false
  t.jsonb :metadata
  t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
end

# DON'T
create_table :car_transfer_events do |t|
  ...
  t.timestamps  # adds updated_at — signals the table is mutable, which it isn't
end
```

### Multi-record atomic operations

```ruby
# DO — car transfer approval
ActiveRecord::Base.transaction do
  transfer.approved!
  car.update!(user_id: transfer.to_user_id)
  # close previous ownership record
  car.car_ownership_records.where(ended_at: nil).update_all(ended_at: Time.current)
  # open new ownership record
  car.car_ownership_records.create!(
    user_id: transfer.to_user_id,
    started_at: Time.current,
    car_transfer_id: transfer.id
  )
  CarTransferEvent.create!(car_transfer: transfer, event_type: :approved, actor: from_user)
  CarTransferEvent.create!(
    car_transfer: transfer,
    event_type: :ownership_transferred,
    metadata: { from_user_id: transfer.from_user_id, to_user_id: transfer.to_user_id }
  )
end

# DON'T — unsynchronized multi-step updates
def approve
  transfer.approved!
  car.update!(user_id: transfer.to_user_id)  # if this fails, transfer is approved but car unchanged
  CarTransferEvent.create!(...)               # audit trail may be incomplete
end
```

### Optimistic locking in forms

```erb
<%# DO — every status transition form includes lock_version %>
<%= form_with url: accept_workshop_management_workshop_service_request_path(@workshop, @service_request),
              method: :patch do |f| %>
  <%= hidden_field_tag :lock_version, @service_request.lock_version %>
  <%= f.submit "Прийняти" %>
<% end %>

<%# DON'T — omitting lock_version %>
<%= form_with url: accept_..., method: :patch do |f| %>
  <%= f.submit "Прийняти" %>  <%# concurrent clicks silently overwrite each other %>
<% end %>
```

### Uniqueness — model + DB

```ruby
# DO — both layers
class WorkshopOperator < ApplicationRecord
  validates :user_id, uniqueness: { scope: :workshop_id }
end

# migration
add_index :workshop_operators, [:user_id, :workshop_id], unique: true

# DON'T — model validation alone
class WorkshopOperator < ApplicationRecord
  validates :user_id, uniqueness: { scope: :workshop_id }
  # no DB index — concurrent requests bypass this validation and create duplicates
end
```

### Case-insensitive uniqueness

```ruby
# DO — normalize before save
class Car < ApplicationRecord
  before_validation :normalize_license_plate

  validates :license_plate, presence: true,
            uniqueness: { case_sensitive: false }

  private

  def normalize_license_plate
    self.license_plate = license_plate&.upcase&.strip
  end
end

# migration
add_index :cars, "lower(license_plate)", unique: true

# DON'T
validates :license_plate, uniqueness: true  # case-sensitive — "AA1234" and "aa1234" allowed as separate
```

---

## Anti-Patterns

- **Skipping `foreign_key: true` on references.** Orphaned records are invisible at query time but corrupt audit trails.
- **Using `update_columns` or `update_all` on append-only tables.** These must be insert-only.
- **`ServiceRecord` created outside a transaction with `service_request.completed!`.** Either both succeed or neither. No half-completed service records.
- **Relying only on `validates_uniqueness_of` for concurrency-sensitive uniqueness.** Race condition: two requests pass validation simultaneously, both insert. DB index is the real guard.
- **Backfilling `lock_version` manually.** It is set to `0` by default at the DB level. Never set it in the controller; let ActiveRecord manage it.
- **Updating `car.odometer` directly from a controller action.** Odometer is updated exclusively in `ServiceRecord#after_create :update_car_odometer`. This ensures the update is tied to a real service event.
- **Reassigning queue positions.** When an entry becomes `no_show`, leave the gap. Never shift other entries' positions — it causes confusion for drivers who've been told their position.
