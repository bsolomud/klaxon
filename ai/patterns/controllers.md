# Pattern: Controllers

## Rules

1. **All controllers inherit `ApplicationController`.** No exceptions. Even `Admin::BaseController` inherits `ApplicationController` (then overrides auth).
2. **`authenticate_user!` is global.** Set in `ApplicationController`. Never set per-action or per-controller in user-facing controllers — it is already active.
3. **Namespace determines layout and auth.**
   - No namespace → `application` layout, `authenticate_user!`
   - `Admin::` → `admin` layout, `authenticate_admin!`, skip `authenticate_user!`
   - `WorkshopManagement::` → `workshop` layout, `set_current_workshop`, `require_workshop_access!`
4. **Query scope always reflects the authenticated principal.**
   - Driver controllers: scope to `current_user` or `current_user.cars`.
   - Workshop management controllers: scope to `@workshop` (set in BaseController).
   - Admin controllers: no scope restriction — admins see everything.
5. **Status transitions are member routes, not magic params.**
   - `patch :accept`, `patch :reject`, `patch :start` — each a dedicated route.
   - Never read a `?action=accept` query param and branch in a single action.
6. **Rescue `ActiveRecord::StaleObjectError` on all optimistic-lock transitions.**
7. **`before_action` for shared setup, not inline guards.**
8. **Never call model callbacks from the controller.** Let `before_create`, `after_create`, etc. fire naturally via `save`/`create`.
9. **Redirect after every non-idempotent action (POST, PATCH, DELETE).** Follow PRG pattern.
10. **No business logic in controllers.** Controllers only: find, permit params, call model methods, redirect/render.

---

## Namespace Structure

```ruby
# ApplicationController — base for all
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def require_workshop_access!(workshop = @workshop)
    redirect_to root_path, alert: "Access denied" unless current_user.manages_workshop?(workshop)
  end
end

# Admin — separate auth, separate layout
class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_admin!
  skip_before_action :authenticate_user!
end

# Workshop management — user auth + workshop scope + workshop layout
class WorkshopManagement::BaseController < ApplicationController
  layout "workshop"
  before_action :set_current_workshop
  before_action :require_workshop_access!

  private

  def set_current_workshop
    @workshop = current_user.workshops.active.find(params[:workshop_id])
  end

  def require_workshop_access!
    redirect_to root_path unless current_user.manages_workshop?(@workshop)
  end
end
```

---

## Do / Don't

### Scoping queries to authenticated principal

```ruby
# DO — driver controller
class ServiceRequestsController < ApplicationController
  def index
    @service_requests = ServiceRequest.where(car: current_user.cars).recent
  end

  def show
    @service_request = ServiceRequest.find_by!(id: params[:id], car: current_user.cars)
  end
end

# DON'T
def show
  @service_request = ServiceRequest.find(params[:id])  # no ownership check
  redirect_to root_path unless @service_request.car.user == current_user  # manual guard — error-prone
end
```

### Workshop management scoping

```ruby
# DO — controller inherits WorkshopManagement::BaseController; @workshop already set + verified
class WorkshopManagement::ServiceRequestsController < WorkshopManagement::BaseController
  def index
    @service_requests = @workshop.service_requests.order(created_at: :desc)
    @service_requests = @service_requests.where(status: params[:status]) if params[:status].present?
  end

  def accept
    @service_request = @workshop.service_requests.find(params[:id])
    @service_request.with_lock { @service_request.accepted! }
    redirect_to workshop_management_workshop_service_request_path(@workshop, @service_request)
  rescue ActiveRecord::StaleObjectError
    redirect_to workshop_management_workshop_service_request_path(@workshop, @service_request),
                alert: "This request was already updated by another action."
  end
end

# DON'T
def accept
  @service_request = ServiceRequest.find(params[:id])  # not scoped to @workshop
  @service_request.update(status: "accepted")           # bypasses enum transition + locks
end
```

### Status transitions as dedicated actions

```ruby
# DO — routes
resources :service_requests, only: [:index, :show] do
  member { patch :accept; patch :reject; patch :start }
end

# DO — controller
def accept
  @service_request.with_lock { @service_request.accepted! }
  redirect_to ...
rescue ActiveRecord::StaleObjectError
  redirect_to ..., alert: "Already updated."
end

# DON'T
def update
  case params[:transition]
  when "accept" then @service_request.accepted!
  when "reject" then @service_request.rejected!
  end
end
```

### Strong parameters

```ruby
# DO
def service_request_params
  params.require(:service_request).permit(
    :car_id, :workshop_id, :workshop_service_category_id,
    :description, :preferred_time
  )
end

# DON'T
params[:service_request]         # no permit
params.permit(:car_id, :status)  # unpermitted status allows status injection
```

### PRG pattern

```ruby
# DO
def create
  @service_request = ServiceRequest.new(service_request_params)
  if @service_request.save
    redirect_to @service_request, notice: "Запит надіслано"
  else
    render :new, status: :unprocessable_entity
  end
end

# DON'T
def create
  ServiceRequest.create!(service_request_params)
  render :show  # renders without redirect — back-button re-submits form
end
```

---

## Anti-Patterns

- **Calling `current_user` in a model.** Models receive data; controllers provide scope. Never thread `current_user` into model callbacks.
- **`before_action :authenticate_user!` in individual controllers.** It is already global. Adding it again is noise.
- **Action branching on a `type` or `action` param.** Every distinct transition is its own route and action.
- **Finding records without scope.** `ServiceRequest.find(id)` without `current_user.cars` scope is a broken access control vulnerability.
- **Inline `redirect_to ... and return` guards.** Extract to `before_action` or a helper method.
- **Workshop management controllers outside the `WorkshopManagement` namespace.** Never put workshop management logic in a driver-facing controller to "keep it simple."
