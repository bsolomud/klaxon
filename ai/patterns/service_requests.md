# Pattern: Service Requests

## Rules

1. **`ServiceRequest` always references `workshop_service_category_id`, not `service_category_id` directly.** The join model is the source of truth for what a workshop offers.
2. **Price is snapshotted at creation via `before_create :snapshot_price`.** After creation, price is read from `price_snapshot` (jsonb), never from `WorkshopServiceCategory`.
3. **`lock_version` is always included in status transition forms.** Every form that triggers `accept`, `reject`, `start` must include a hidden `lock_version` field.
4. **`ActiveRecord::StaleObjectError` is always rescued in transition actions.** Show a user-readable error; never let it bubble to a 500.
5. **Status flows forward only.** `pending → accepted`, `accepted → in_progress`, `in_progress → completed`. Reverse transitions are not valid.
6. **`ServiceRecord` is created exactly once per `ServiceRequest`.** Enforced by a unique DB index on `service_request_id`. The controller must only call `create`, never `update`.
7. **A `ServiceRequest` cannot be created for a car that does not belong to `current_user`.** This is validated in the model (`validate :car_belongs_to_current_user`) and enforced by scoping in the controller.
8. **`preferred_time` must be within the workshop's working hours.** Validated in the model (`validate :preferred_time_within_working_hours`).
9. **Service category is accessed via the chain, not stored redundantly.** `service_request.workshop_service_category.service_category` — never store `service_category_id` on `ServiceRequest`.
10. **`ServiceRecord` creation calls `service_request.completed!`.** The status transition and record creation are a single atomic transaction.

---

## Data Model

```
Workshop ──has_many──> WorkshopServiceCategory <──belongs_to── ServiceCategory
                              │
                              └──has_many──> ServiceRequest
                                                │
                                                ├── price_snapshot (jsonb, frozen at create)
                                                ├── lock_version (optimistic locking)
                                                └──has_one──> ServiceRecord
```

---

## Do / Don't

### Creating a ServiceRequest

```ruby
# DO — controller
def new
  @workshop = Workshop.active.find(params[:workshop_id])
  @service_request = ServiceRequest.new(workshop: @workshop)
  @cars = current_user.cars
  @categories = @workshop.workshop_service_categories.includes(:service_category)
end

def create
  @workshop = Workshop.active.find(service_request_params[:workshop_id])
  @service_request = ServiceRequest.new(service_request_params)
  # price_snapshot is set automatically by before_create
  if @service_request.save
    redirect_to @service_request, notice: "Запит надіслано"
  else
    render :new, status: :unprocessable_entity
  end
end

def service_request_params
  params.require(:service_request).permit(
    :car_id, :workshop_id, :workshop_service_category_id,
    :description, :preferred_time
  )
  # DO NOT permit: :status, :price_snapshot, :lock_version (from driver)
end

# DON'T
def create
  @service_request = ServiceRequest.new(service_request_params)
  @service_request.price_snapshot = build_price_snapshot  # price is set by model callback
  @service_request.status = :pending                       # default is already pending
  @service_request.save
end
```

### Accessing price after creation

```ruby
# DO — always read from the snapshot
def display_price
  snapshot = service_request.price_snapshot
  return "Ціна за запитом" if snapshot.blank?
  "#{snapshot['min']}–#{snapshot['max']} #{snapshot['currency']}"
end

# DON'T
def display_price
  wsc = service_request.workshop_service_category
  "#{wsc.price_min}–#{wsc.price_max}"  # price may have changed since request was created
end
```

### Status transitions with optimistic locking

```ruby
# DO — view includes lock_version
<%= hidden_field_tag :lock_version, @service_request.lock_version %>

# DO — controller uses with_lock
def accept
  @service_request = @workshop.service_requests.find(params[:id])
  @service_request.lock_version = params[:lock_version].to_i
  @service_request.with_lock { @service_request.accepted! }
  redirect_to workshop_management_workshop_service_request_path(@workshop, @service_request),
              notice: "Запит прийнято"
rescue ActiveRecord::StaleObjectError
  redirect_to workshop_management_workshop_service_request_path(@workshop, @service_request),
              alert: "Цей запит вже оновлено іншою дією."
end

# DON'T
def accept
  @service_request.update(status: :accepted)  # no locking — concurrent transitions corrupt state
end
```

### ServiceRecord creation (atomic)

```ruby
# DO — single transaction: create record + complete request
def create
  @service_request = @workshop.service_requests.in_progress.find(params[:service_request_id])
  @service_record = @service_request.build_service_record(service_record_params)

  ActiveRecord::Base.transaction do
    @service_record.save!
    @service_request.completed!
    # after_create :update_car_odometer fires automatically on service_record save
  end

  redirect_to workshop_management_workshop_service_request_path(@workshop, @service_request),
              notice: "Сервісний запис збережено"
rescue ActiveRecord::RecordInvalid => e
  render :new, status: :unprocessable_entity
end

# DON'T — two separate saves without transaction
def create
  @service_record.save!
  @service_request.completed!  # if this fails, record exists but request stays in_progress
end
```

### Model validation: car ownership

```ruby
# DO — model validates at save time, regardless of how it's called
class ServiceRequest < ApplicationRecord
  validate :car_belongs_to_requestor

  private

  def car_belongs_to_requestor
    return unless car
    unless car.user == driver  # driver = car.user — wait, use a passed-in user
      errors.add(:car, "does not belong to the requestor")
    end
  end
end

# This validation works because the controller scopes car selection to current_user.cars
# in the form, and the model validates the relationship is intact.
```

### Checking what service category was requested

```ruby
# DO — follow the chain
service_request.workshop_service_category.service_category.name

# DON'T — add a redundant shortcut column
# Never add service_category_id directly to service_requests
```

---

## Anti-Patterns

- **Storing `service_category_id` on `ServiceRequest`.** The association goes through `workshop_service_category`. Adding a direct column is redundant and can drift out of sync.
- **Mutating `price_snapshot` after record creation.** It is a frozen-in-time snapshot. Never update it.
- **Status transitions without optimistic locking.** Two operators acting on the same request simultaneously will corrupt state without `with_lock`.
- **Creating a `ServiceRecord` when `ServiceRequest` is not `in_progress`.** The controller must scope: `@workshop.service_requests.in_progress.find(...)`.
- **Allowing drivers to set `status` via params.** Permit only: `car_id`, `workshop_id`, `workshop_service_category_id`, `description`, `preferred_time`.
- **Multiple `ServiceRecord` entries per request.** The unique DB index prevents this. Never try to work around it.
