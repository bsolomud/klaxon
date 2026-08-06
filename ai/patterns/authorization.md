# Pattern: Authorization

## Rules

1. **Two Devise models, two authentication paths.** `User` for everyone in the app. `Admin` for platform administrators. Never conflate them.
2. **Workshop access is from the join table, not from `User#role`.** `current_user.manages_workshop?(@workshop)` — this is the only check that matters.
3. **`WorkshopManagement::BaseController` is the enforcement point** for all workshop management access. Authorization is not repeated in individual controllers.
4. **`Admin::BaseController` skips `authenticate_user!`.** Admin sessions are completely separate. An admin visiting `/admin/` is not authenticated as a User.
5. **Drivers own their own cars, requests, and history.** All driver queries scope to `current_user` or `current_user.cars`. No exceptions.
6. **Workshop operators can only see their own workshop's data.** `@workshop.service_requests`, not `ServiceRequest.all`. `@workshop` is already scoped to the current user in `BaseController`.
7. **Admins see all workshops regardless of status.** Driver-facing workshop queries must always filter by `status: :active`.
8. **`require_workshop_access!` must always receive the current workshop, never a user-supplied ID directly.**
9. **No role-based checks in views.** Authorization decisions are in controllers. Views receive already-scoped data.
10. **Pundit/CanCanCan are not used.** Authorization is plain Ruby methods on models and controllers.

---

## Authorization Decision Tree

```
Request arrives
  ├── /admin/* → authenticate_admin! (Admin::BaseController)
  │               skip authenticate_user!
  │               If no admin session → redirect to /admin/auth/sign_in
  │
  ├── /workshop_management/* → authenticate_user! (inherited)
  │                            set_current_workshop (scoped to current_user.workshops.active)
  │                            require_workshop_access! (manages_workshop? check)
  │                            If no workshop found → 404 (find raises RecordNotFound)
  │                            If no access → redirect root_path
  │
  └── /* → authenticate_user! (ApplicationController)
           If no user session → redirect to sign_in
           Driver controllers scope all queries to current_user
```

---

## Do / Don't

### Workshop access check

```ruby
# DO — in WorkshopManagement::BaseController
def set_current_workshop
  # find scoped to current_user.workshops means non-members get 404 automatically
  @workshop = current_user.workshops.active.find(params[:workshop_id])
end

def require_workshop_access!
  redirect_to root_path unless current_user.manages_workshop?(@workshop)
end

# DON'T — checking role instead of join table
def require_workshop_access!
  redirect_to root_path unless current_user.role == "operator"  # no operator role exists
end

# DON'T — using global find
def set_current_workshop
  @workshop = Workshop.find(params[:workshop_id])  # no ownership check
  require_workshop_access!                          # this alone is not enough — user could guess IDs
end
```

### Admin isolation

```ruby
# DO
class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_admin!
  skip_before_action :authenticate_user!
end

# DON'T — trying to reuse user session for admin
class Admin::BaseController < ApplicationController
  before_action :require_admin_role!

  def require_admin_role!
    redirect_to root_path unless current_user&.admin?  # there is no admin? on User
  end
end
```

### Driver data scoping

```ruby
# DO
def show
  @car = current_user.cars.find(params[:id])  # 404 if not owner
end

def index
  @service_requests = ServiceRequest.where(car: current_user.cars).recent
end

# DON'T
def show
  @car = Car.find(params[:id])
  redirect_to cars_path unless @car.user == current_user  # exposes record existence via 302 vs 404
end
```

### Workshop status in driver-facing queries

```ruby
# DO
def index
  @workshops = Workshop.active.includes(:service_categories, :working_hours)
end

def show
  @workshop = Workshop.active.find(params[:id])
end

# DON'T
def show
  @workshop = Workshop.find(params[:id])  # exposes pending/declined workshops to drivers
end
```

### No authorization logic in views

```erb
<%# DO — controller already scoped the data; view just renders %>
<% @workshops.each do |workshop| %>
  <%= workshop.name %>
<% end %>

<%# DON'T — authorization in view %>
<% Workshop.all.each do |workshop| %>
  <% if workshop.active? && current_user.manages_workshop?(workshop) %>
    ...
  <% end %>
<% end %>
```

### CarTransfer token authorization

```ruby
# DO — token-based approval (no session required for the from_user click)
def approve
  @transfer = CarTransfer.find_by!(token: params[:token], status: :requested)
  raise ActiveRecord::RecordNotFound if @transfer.expired?
  ActiveRecord::Base.transaction do
    @transfer.approved!
    @transfer.car.update!(user_id: @transfer.to_user_id)
    # ... ownership record updates + events
  end
end

# DON'T
def approve
  @transfer = CarTransfer.find(params[:id])  # no token check — enumerable by ID
  @transfer.approved!
end
```

---

## Anti-Patterns

- **Checking `user.role` to grant workshop access.** There is no operator role. Role enum is for future extensibility, not current access control.
- **Sharing admin/user sessions.** They are separate Devise models. There is no `current_user` in admin controllers (only `current_admin`).
- **Authorization in the model.** Models validate data integrity, not who is allowed to act. Controllers enforce access.
- **Relying on hidden form fields for authorization.** Never trust `params[:workshop_id]` unless it is also validated against `current_user.workshops`.
- **Skipping `require_workshop_access!` in a subclass.** Every `WorkshopManagement::` controller inherits the check. Never override or skip it in a subclass.
