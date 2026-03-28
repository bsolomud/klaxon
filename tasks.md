# AULABS — AI Agent Task Graph

> 65 tasks, ordered by dependency. Each task is small (1–2 files), testable, and independent within its dependency tier.

---

## Phase 1 — User Roles + Admin Model [DONE]

### Task 1: Add role enum to User model
- **Description**: Add integer `role` column to users (default 0 = driver). Add `enum :role, { driver: 0 }` to User model.
- **Files**: `db/migrate/xxx_add_role_to_users.rb`, `app/models/user.rb`
- **Acceptance Criteria**:
  - Migration runs cleanly
  - `User.new.driver?` returns true
  - `bin/rails test test/models/user_test.rb` passes

### Task 2: Create Admin Devise model
- **Description**: Generate separate Devise model `Admin` with its own table (`admins`). Only `:database_authenticatable, :rememberable, :validatable`.
- **Files**: `db/migrate/xxx_create_admins.rb`, `app/models/admin.rb`, `test/models/admin_test.rb`, `test/fixtures/admins.yml`
- **Acceptance Criteria**:
  - `Admin.create!(email: "a@b.com", password: "password")` works
  - Admin and User are completely separate tables
  - `bin/rails test test/models/admin_test.rb` passes

### Task 3: Add Admin Devise routes
- **Description**: Add `devise_for :admins, path: "admin/auth"` to routes. Verify sign-in page renders at `/admin/auth/sign_in`.
- **Files**: `config/routes.rb`
- **Acceptance Criteria**:
  - `GET /admin/auth/sign_in` returns 200
  - No conflict with existing User Devise routes

### Task 4: Create Admin::BaseController
- **Description**: Create base controller for admin namespace. Sets `layout "admin"`, calls `authenticate_admin!`, skips `authenticate_user!`.
- **Files**: `app/controllers/admin/base_controller.rb`
- **Acceptance Criteria**:
  - Unauthenticated request to any admin route redirects to `/admin/auth/sign_in`
  - Authenticated admin can access admin routes

### Task 5: Create admin layout
- **Description**: Create `app/views/layouts/admin.html.erb` — minimal layout with nav (Workshops, Users, Sign out). TailwindCSS styled, Ukrainian UI text.
- **Files**: `app/views/layouts/admin.html.erb`
- **Acceptance Criteria**:
  - Layout renders without errors
  - Contains navigation links for admin sections

### Task 6: Seed Admin record
- **Description**: Add one Admin record to `db/seeds.rb` for development (email: `admin@aulabs.dev`, password from `ENV["ADMIN_PASSWORD"]` or fallback `"password"`).
- **Files**: `db/seeds.rb`
- **Acceptance Criteria**:
  - `bin/rails db:seed` creates admin record
  - Admin can sign in at `/admin/auth/sign_in`

---

## Phase 2 — Workshop Operators + Status [DONE]

### Task 7: Create WorkshopOperator model + migration
- **Description**: Create `workshop_operators` table: `user_id` (fk), `workshop_id` (fk), `role` (integer, default 0). Unique index on `[user_id, workshop_id]`. Model with `enum :role, { owner: 0, staff: 1 }`.
- **Files**: `db/migrate/xxx_create_workshop_operators.rb`, `app/models/workshop_operator.rb`, `test/models/workshop_operator_test.rb`, `test/fixtures/workshop_operators.yml`
- **Acceptance Criteria**:
  - Migration runs cleanly
  - `WorkshopOperator.new.owner?` returns true
  - Duplicate `[user_id, workshop_id]` raises unique constraint error
  - Model tests pass

### Task 8: Add workshop associations to User
- **Description**: Add `has_many :workshop_operators`, `has_many :workshops, through: :workshop_operators` to User. Add helper methods: `workshop_owner?`, `manages_workshop?(workshop)`, `full_name`.
- **Files**: `app/models/user.rb`, `test/models/user_test.rb`
- **Acceptance Criteria**:
  - `user.workshops` returns workshops via join table
  - `user.manages_workshop?(workshop)` returns true/false correctly
  - `user.workshop_owner?` returns true when user has owner role
  - Tests pass

### Task 9: Add operator associations to Workshop
- **Description**: Add `has_many :workshop_operators`, `has_many :members, through: :workshop_operators, source: :user` to Workshop.
- **Files**: `app/models/workshop.rb`, `test/models/workshop_test.rb`
- **Acceptance Criteria**:
  - `workshop.members` returns users via join table
  - Tests pass

### Task 10: Add status enum + decline_reason to Workshop
- **Description**: Add migration for `status` (integer, default 0) and `decline_reason` (text, nullable) on workshops. Add `enum :status, { pending: 0, active: 1, declined: 2, suspended: 3 }` and `scope :active`.
- **Files**: `db/migrate/xxx_add_status_to_workshops.rb`, `db/migrate/xxx_add_decline_reason_to_workshops.rb`, `app/models/workshop.rb`, `test/models/workshop_test.rb`
- **Acceptance Criteria**:
  - New workshops default to `pending`
  - `Workshop.active` returns only active workshops
  - Status transitions work: `workshop.active!`, `workshop.declined!`, `workshop.suspended!`
  - `decline_reason` can be set on decline
  - Tests pass

### Task 11: Add require_workshop_access! to ApplicationController
- **Description**: Add `require_workshop_access!(workshop)` helper that redirects unless `current_user.manages_workshop?(workshop)`.
- **Files**: `app/controllers/application_controller.rb`
- **Acceptance Criteria**:
  - Non-manager is redirected with flash
  - Manager passes through

---

## Phase 3 — Workshop Service Categories + Pricing [DONE]

### Task 12: Create WorkshopServiceCategory model + migration
- **Description**: Create `workshop_service_categories` table: `workshop_id` (fk), `service_category_id` (fk), `price_min` (decimal 10,2), `price_max` (decimal 10,2), `price_unit` (string), `currency` (string, default "UAH"), `estimated_duration_minutes` (integer). Unique index on `[workshop_id, service_category_id]`.
- **Files**: `db/migrate/xxx_create_workshop_service_categories.rb`, `app/models/workshop_service_category.rb`, `test/models/workshop_service_category_test.rb`, `test/fixtures/workshop_service_categories.yml`
- **Acceptance Criteria**:
  - Migration runs cleanly
  - Unique constraint enforced
  - Model tests pass

### Task 13: Add pricing display methods to WorkshopServiceCategory
- **Description**: Add `price_display` (returns "500–1500 UAH / per service" or "Ціна за запитом") and `duration_display` (returns "~45 хв" or nil).
- **Files**: `app/models/workshop_service_category.rb`, `test/models/workshop_service_category_test.rb`
- **Acceptance Criteria**:
  - `price_display` formats correctly for all cases (both prices, one price, no price)
  - `duration_display` returns Ukrainian time format or nil
  - Tests pass

### Task 14: Update Workshop associations for many service categories
- **Description**: Replace `belongs_to :service_category` with `has_many :workshop_service_categories` + `has_many :service_categories, through: :workshop_service_categories` on Workshop. Same inverse on ServiceCategory.
- **Files**: `app/models/workshop.rb`, `app/models/service_category.rb`
- **Acceptance Criteria**:
  - `workshop.service_categories` returns categories via join table
  - `service_category.workshops` returns workshops via join table

### Task 15: Remove service_category_id from workshops table
- **Description**: Migration to remove `service_category_id` column from workshops. Update any code referencing `workshop.service_category` to use the new many-to-many.
- **Files**: `db/migrate/xxx_remove_service_category_id_from_workshops.rb`
- **Acceptance Criteria**:
  - Migration runs cleanly (up and down)
  - No references to `workshop.service_category` (singular) remain

### Task 16: Update Workshop form for multi-select categories
- **Description**: Update workshop new/edit form to use multi-select `service_category_ids[]` checkboxes instead of single select.
- **Files**: `app/views/workshops/_form.html.erb`, `app/controllers/workshops_controller.rb`
- **Acceptance Criteria**:
  - Form renders checkboxes for all service categories
  - Submitting creates `WorkshopServiceCategory` records
  - Editing preserves selections

### Task 17: Add per-category pricing fields to Workshop form
- **Description**: Add pricing fields (price_min, price_max, price_unit, estimated_duration_minutes) per selected category. Stimulus controller to show/hide fields dynamically.
- **Files**: `app/views/workshops/_form.html.erb`, `app/javascript/controllers/pricing_fields_controller.js`, `config/importmap.rb` (if pin needed)
- **Acceptance Criteria**:
  - Selecting a category reveals pricing fields for it
  - Deselecting hides them
  - Pricing data saves correctly

### Task 18: Display service categories + pricing on Workshop show page
- **Description**: Show services table on workshop show with columns: category name, price, duration.
- **Files**: `app/views/workshops/show.html.erb`
- **Acceptance Criteria**:
  - Table renders with all offered services
  - "Ціна за запитом" shown when no price set
  - Duration shown when available

### Task 19: Update by_category_slug scope to use joins
- **Description**: Update `by_category_slug` scope on Workshop to use `joins(:service_categories)` instead of direct `service_category_id`.
- **Files**: `app/models/workshop.rb`
- **Acceptance Criteria**:
  - Filtering workshops by category still works on index page
  - Tests pass

### Task 20: Update seeds for workshop_service_categories
- **Description**: Update `db/seeds.rb` to populate `workshop_service_categories` join table with pricing for seeded workshops.
- **Files**: `db/seeds.rb`
- **Acceptance Criteria**:
  - `bin/rails db:seed` creates workshop_service_categories records
  - Each seeded workshop has at least one service category with pricing

---

## Phase 4 — Admin Workshop Management [DONE]

### Task 21: Admin::WorkshopsController — index + show
- **Description**: Create controller inheriting `Admin::BaseController`. Index: all workshops filterable by status. Show: workshop detail + owner info.
- **Files**: `app/controllers/admin/workshops_controller.rb`, `app/views/admin/workshops/index.html.erb`, `app/views/admin/workshops/show.html.erb`, `test/controllers/admin/workshops_controller_test.rb`
- **Acceptance Criteria**:
  - Index lists workshops with status filter
  - Show displays workshop details and owner
  - Only authenticated admins can access
  - Tests pass

### Task 22: Admin::WorkshopsController — approve action
- **Description**: Add `approve` member PATCH action. Sets `workshop.active!`.
- **Files**: `app/controllers/admin/workshops_controller.rb`, `app/views/admin/workshops/show.html.erb`
- **Acceptance Criteria**:
  - Approving a pending workshop sets status to active
  - Button visible only for pending workshops
  - Tests pass

### Task 23: Admin::WorkshopsController — decline action
- **Description**: Add `decline` member PATCH action with optional `decline_reason` param. Sets `workshop.declined!` and saves reason.
- **Files**: `app/controllers/admin/workshops_controller.rb`, `app/views/admin/workshops/show.html.erb`
- **Acceptance Criteria**:
  - Declining sets status to declined and stores reason
  - Decline form/modal with reason text field
  - Tests pass

### Task 24: Admin::WorkshopsController — suspend action
- **Description**: Add `suspend` member PATCH action. Sets `workshop.suspended!`. Only for active workshops.
- **Files**: `app/controllers/admin/workshops_controller.rb`, `app/views/admin/workshops/show.html.erb`
- **Acceptance Criteria**:
  - Suspending an active workshop sets status to suspended
  - Button visible only for active workshops
  - Tests pass

### Task 25: Admin workshop routes
- **Description**: Add admin namespace routes: `resources :workshops` with member actions + `resources :users, only: [:index, :show]` + `root to: "workshops#index"`.
- **Files**: `config/routes.rb`
- **Acceptance Criteria**:
  - All admin routes resolve correctly
  - `admin_root_path` works

### Task 26: Admin::UsersController — index + show
- **Description**: Basic user list and detail view for admins. Read-only for MVP.
- **Files**: `app/controllers/admin/users_controller.rb`, `app/views/admin/users/index.html.erb`, `app/views/admin/users/show.html.erb`
- **Acceptance Criteria**:
  - Lists all users with basic info
  - Show displays user detail + their workshops/cars
  - Only admins can access

---

## Phase 5 — Workshop Self-Registration [DONE]

### Task 27: Add geocoordinates to workshops
- **Description**: Migration to add `latitude` (decimal, precision: 10, scale: 6) and `longitude` (decimal, precision: 10, scale: 6), both nullable, to workshops.
- **Files**: `db/migrate/xxx_add_geocoordinates_to_workshops.rb`
- **Acceptance Criteria**:
  - Migration runs cleanly
  - Columns accept decimal values

### Task 28: Add geocoding to Workshop model
- **Description**: Add `geocoder` gem. Add `after_validation :geocode, if: :address_changed?` to Workshop. Configure Geocoder for MVP (nominatim or similar free provider).
- **Files**: `Gemfile`, `app/models/workshop.rb`, `config/initializers/geocoder.rb`
- **Acceptance Criteria**:
  - Saving a workshop with an address populates lat/lng
  - Works with test/development environments

### Task 29: Add proximity filter to workshops index
- **Description**: Add `near` query param to workshops index (`/workshops?near=lat,lng`). Use bounding box for MVP.
- **Files**: `app/controllers/workshops_controller.rb`, `app/models/workshop.rb`
- **Acceptance Criteria**:
  - `/workshops?near=50.45,30.52` returns workshops within radius
  - Without `near` param, behavior unchanged

### Task 30: Workshop submission creates pending + owner
- **Description**: Update `WorkshopsController#create` to set `status: :pending` and create `WorkshopOperator(role: :owner)` for `current_user`.
- **Files**: `app/controllers/workshops_controller.rb`, `test/controllers/workshops_controller_test.rb`
- **Acceptance Criteria**:
  - New workshop has status `pending`
  - Current user is owner via `workshop_operators`
  - Flash: "Your workshop has been submitted for review"
  - Tests pass

### Task 31: Workshop index shows only active workshops
- **Description**: Update `WorkshopsController#index` to scope to `Workshop.active` for browsing. Workshop owners still see their own pending/declined workshops separately.
- **Files**: `app/controllers/workshops_controller.rb`
- **Acceptance Criteria**:
  - Public index only shows active workshops
  - No pending/declined workshops visible to other users

### Task 32: My Workshops section — controller + view
- **Description**: Add a section (could be `MyWorkshopsController#index` or part of dashboard) listing workshops the current user manages. Shows status badges and decline_reason.
- **Files**: `app/controllers/my_workshops_controller.rb`, `app/views/my_workshops/index.html.erb`, `config/routes.rb`
- **Acceptance Criteria**:
  - Lists workshops user owns/staffs
  - Status badges: pending (spinner), active (green), declined (red with reason), suspended (yellow)
  - Links to workshop management if active

---

## Phase 6 — Workshop Management Layout + Namespace [DONE]

### Task 33: Create workshop management layout
- **Description**: Create `app/views/layouts/workshop.html.erb` — sidebar with workshop name, status, nav links (Requests, Queue, Settings). Workshop switcher if user manages multiple.
- **Files**: `app/views/layouts/workshop.html.erb`
- **Acceptance Criteria**:
  - Layout renders without errors
  - Sidebar shows workshop name and navigation
  - Ukrainian UI text

### Task 34: Create WorkshopManagement::BaseController
- **Description**: Base controller setting `layout "workshop"`, `set_current_workshop` from `params[:workshop_id]`, `require_workshop_access!`.
- **Files**: `app/controllers/workshop_management/base_controller.rb`
- **Acceptance Criteria**:
  - `@workshop` resolved from `current_user.workshops.active.find(params[:workshop_id])`
  - Non-manager redirected to root
  - Workshop context always from URL, never session

### Task 35: Workshop management routes skeleton
- **Description**: Add `namespace :workshop_management` routes with nested `resources :workshops` for service_requests, service_records, queues, queue_entries.
- **Files**: `config/routes.rb`
- **Acceptance Criteria**:
  - Routes resolve correctly
  - `bin/rails routes` shows all workshop_management paths

### Task 36: Workshop management dashboard
- **Description**: Create `WorkshopManagement::DashboardController#show` as the landing page for a workshop. Shows summary stats (pending requests count, today's queue size).
- **Files**: `app/controllers/workshop_management/dashboard_controller.rb`, `app/views/workshop_management/dashboard/show.html.erb`
- **Acceptance Criteria**:
  - Renders within workshop layout
  - Shows workshop overview

---

## Phase 7 — Car Model [DONE]

### Task 37: Create Car model + migration
- **Description**: Create `cars` table: `user_id` (fk), `make`, `model`, `year` (int), `license_plate` (unique), `vin` (unique, nullable), `fuel_type` (int, default 0), `odometer` (int, nullable), `engine_volume` (decimal 3,1, nullable), `transmission` (int, nullable).
- **Files**: `db/migrate/xxx_create_cars.rb`, `app/models/car.rb`, `test/models/car_test.rb`, `test/fixtures/cars.yml`
- **Acceptance Criteria**:
  - Migration runs cleanly
  - Enums: `fuel_type { gasoline: 0, diesel: 1, electric: 2, hybrid: 3 }`, `transmission { manual: 0, automatic: 1 }`
  - Validations: make, model, year, license_plate, fuel_type required; year > 1885; VIN length 17; license_plate unique (case-insensitive); engine_volume nil when electric
  - `display_name` returns "2020 Toyota Camry"
  - Tests pass

### Task 38: Add Car association to User
- **Description**: Add `has_many :cars` to User model.
- **Files**: `app/models/user.rb`
- **Acceptance Criteria**:
  - `user.cars` returns the user's cars

### Task 39: CarsController — index + show
- **Description**: Create `CarsController` with `index` (current_user's cars) and `show` (car details + placeholder for service history).
- **Files**: `app/controllers/cars_controller.rb`, `app/views/cars/index.html.erb`, `app/views/cars/show.html.erb`, `config/routes.rb`, `test/controllers/cars_controller_test.rb`
- **Acceptance Criteria**:
  - Index scoped to `current_user.cars`
  - Show displays car details
  - Cannot view another user's cars
  - Tests pass

### Task 40: CarsController — new + create
- **Description**: Add `new` and `create` actions. Form with all car fields. Assign `current_user` as owner.
- **Files**: `app/controllers/cars_controller.rb`, `app/views/cars/_form.html.erb`, `app/views/cars/new.html.erb`
- **Acceptance Criteria**:
  - Form renders with all fields including fuel_type select, optional VIN
  - Create assigns car to current_user
  - Validation errors display correctly

### Task 41: CarsController — edit + update + destroy
- **Description**: Add remaining CRUD actions. Ownership guard on all actions.
- **Files**: `app/controllers/cars_controller.rb`, `app/views/cars/edit.html.erb`
- **Acceptance Criteria**:
  - Only car owner can edit/update/destroy
  - Destroy removes car (with confirmation)
  - Tests pass

### Task 42: VIN duplicate detection on Car create
- **Description**: When creating a car with a VIN that already exists, block creation and show claim prompt: "This vehicle is already registered. Request a transfer."
- **Files**: `app/controllers/cars_controller.rb`, `app/views/cars/new.html.erb`
- **Acceptance Criteria**:
  - Duplicate VIN does not create new car
  - User sees message with link to initiate transfer
  - Unique VINs still create normally

---

## Phase 8 — Car Transfers

### Task 43: Create CarTransfer model + migration
- **Description**: Create `car_transfers` table: `car_id` (fk), `from_user_id` (fk), `to_user_id` (fk), `status` (int, default 0), `token` (string, unique), `expires_at` (datetime). Partial unique index on `car_id` where `status = 0`.
- **Files**: `db/migrate/xxx_create_car_transfers.rb`, `app/models/car_transfer.rb`, `test/models/car_transfer_test.rb`, `test/fixtures/car_transfers.yml`
- **Acceptance Criteria**:
  - Enum: `{ requested: 0, approved: 1, rejected: 2, cancelled: 3, expired: 4 }`
  - Only one active (requested) transfer per car enforced at DB level
  - Token generated on create
  - Tests pass

### Task 44: Create CarTransferEvent model + migration
- **Description**: Create `car_transfer_events` table: `car_transfer_id` (fk), `actor_id` (fk → users), `event_type` (int), `metadata` (jsonb), `created_at`. **No `updated_at`** — append-only.
- **Files**: `db/migrate/xxx_create_car_transfer_events.rb`, `app/models/car_transfer_event.rb`, `test/models/car_transfer_event_test.rb`, `test/fixtures/car_transfer_events.yml`
- **Acceptance Criteria**:
  - Enum: `{ transfer_requested: 0, notification_sent: 1, approved: 2, rejected: 3, cancelled: 4, expired: 5, ownership_transferred: 6 }`
  - No `updated_at` column
  - Records cannot be updated or destroyed (model-level guard)
  - Tests pass

### Task 45: Create CarOwnershipRecord model + migration
- **Description**: Create `car_ownership_records` table: `car_id` (fk), `user_id` (fk), `started_at` (datetime, not null), `ended_at` (datetime, nullable), `car_transfer_id` (fk, nullable), `created_at`.
- **Files**: `db/migrate/xxx_create_car_ownership_records.rb`, `app/models/car_ownership_record.rb`, `test/models/car_ownership_record_test.rb`, `test/fixtures/car_ownership_records.yml`
- **Acceptance Criteria**:
  - `ended_at: nil` means current owner
  - Append-only (no updates to historical records)
  - Tests pass

### Task 46: Create initial CarOwnershipRecord on Car create
- **Description**: After creating a car, create a `CarOwnershipRecord` with `started_at: Time.current`, `ended_at: nil`, `car_transfer_id: nil` (original registration).
- **Files**: `app/models/car.rb`
- **Acceptance Criteria**:
  - Creating a car auto-creates ownership record
  - `car.car_ownership_records.count == 1`

### Task 47: CarTransfersController — initiate transfer
- **Description**: `new` and `create` actions. Initiates transfer: creates CarTransfer + CarTransferEvent(transfer_requested). Requires existing car with different owner.
- **Files**: `app/controllers/car_transfers_controller.rb`, `app/views/car_transfers/new.html.erb`, `config/routes.rb`, `test/controllers/car_transfers_controller_test.rb`
- **Acceptance Criteria**:
  - Creates transfer with token and expires_at (14 days)
  - Creates transfer_requested event
  - Cannot transfer own car to self
  - Tests pass

### Task 48: CarTransfersController — approve transfer
- **Description**: `approve` member PATCH. Token-based: from_user clicks link. Updates car.user_id, closes old ownership record, opens new one, creates events.
- **Files**: `app/controllers/car_transfers_controller.rb`, `app/views/car_transfers/show.html.erb`
- **Acceptance Criteria**:
  - Only `from_user` can approve
  - Car ownership transfers to `to_user`
  - Old CarOwnershipRecord gets `ended_at`
  - New CarOwnershipRecord created
  - Events: approved + ownership_transferred
  - Tests pass

### Task 49: CarTransfersController — reject + cancel
- **Description**: `reject` (from_user) and `cancel` (to_user) member PATCH actions with corresponding events.
- **Files**: `app/controllers/car_transfers_controller.rb`
- **Acceptance Criteria**:
  - Reject: only from_user, creates rejected event
  - Cancel: only to_user, creates cancelled event
  - Transfer status updated correctly
  - Tests pass

### Task 50: Car transfer expiration job
- **Description**: SolidQueue job that finds expired transfers (`expires_at < Time.current` and `status: requested`) and marks them `expired` with event.
- **Files**: `app/jobs/expire_car_transfers_job.rb`, `test/jobs/expire_car_transfers_job_test.rb`
- **Acceptance Criteria**:
  - Expired transfers get status `:expired`
  - CarTransferEvent created with `event_type: :expired`
  - Non-expired transfers untouched
  - Tests pass

---

## Phase 9 — Service Requests (Driver Side)

### Task 51: Create ServiceRequest model + migration
- **Description**: Create `service_requests` table: `car_id` (fk), `workshop_id` (fk), `workshop_service_category_id` (fk), `price_snapshot` (jsonb), `status` (int, default 0), `description` (text), `preferred_time` (datetime), `lock_version` (int, default 0). Indexes on `[workshop_id, status]` and `[car_id, status]`.
- **Files**: `db/migrate/xxx_create_service_requests.rb`, `app/models/service_request.rb`, `test/models/service_request_test.rb`, `test/fixtures/service_requests.yml`
- **Acceptance Criteria**:
  - Enum: `{ pending: 0, accepted: 1, rejected: 2, in_progress: 3, completed: 4 }`
  - Validations: description, preferred_time required
  - `lock_version` present for optimistic locking
  - Tests pass

### Task 52: ServiceRequest — price snapshot callback
- **Description**: Add `before_create :snapshot_price` that copies pricing from `workshop_service_category` into `price_snapshot` jsonb field.
- **Files**: `app/models/service_request.rb`, `test/models/service_request_test.rb`
- **Acceptance Criteria**:
  - Creating a request auto-populates `price_snapshot` from current WSC pricing
  - Changing WSC pricing after creation does not affect existing requests
  - Tests pass

### Task 53: ServiceRequest — custom validations
- **Description**: Add `validate :car_belongs_to_user` (car.user_id matches), `validate :service_offered_by_workshop` (WSC.workshop_id matches workshop_id).
- **Files**: `app/models/service_request.rb`, `test/models/service_request_test.rb`
- **Acceptance Criteria**:
  - Cannot create request for someone else's car
  - Cannot create request for service not offered by workshop
  - Tests pass

### Task 54: ServiceRequestsController — index + show
- **Description**: `index`: all requests across `current_user.cars`. `show`: own requests only, with price_snapshot display.
- **Files**: `app/controllers/service_requests_controller.rb`, `app/views/service_requests/index.html.erb`, `app/views/service_requests/show.html.erb`, `config/routes.rb`, `test/controllers/service_requests_controller_test.rb`
- **Acceptance Criteria**:
  - Index scoped to current user's cars' requests
  - Show displays request details + price snapshot
  - Cannot view another user's requests
  - Tests pass

### Task 55: ServiceRequestsController — new + create
- **Description**: `new`: requires `?workshop_id=` param, loads user's cars + workshop's WSCs. Pre-selects car if user has one. `create`: validates and saves.
- **Files**: `app/controllers/service_requests_controller.rb`, `app/views/service_requests/_form.html.erb`, `app/views/service_requests/new.html.erb`
- **Acceptance Criteria**:
  - Form shows car select + service category select + description + preferred_time
  - Pre-selects car if user has exactly one
  - Price snapshot saved on create
  - Tests pass

### Task 56: Add "Request Service" button to Workshop show
- **Description**: Add "Замовити послугу" button on workshop show page linking to `new_service_request_path(workshop_id: @workshop.id)`.
- **Files**: `app/views/workshops/show.html.erb`
- **Acceptance Criteria**:
  - Button visible on active workshop show pages
  - Links correctly with workshop_id param

---

## Phase 10 — Workshop Management: Request Handling

### Task 57: WM::ServiceRequestsController — index + show
- **Description**: `index`: `@workshop.service_requests` filterable by status. `show`: request detail with car info, price, driver description.
- **Files**: `app/controllers/workshop_management/service_requests_controller.rb`, `app/views/workshop_management/service_requests/index.html.erb`, `app/views/workshop_management/service_requests/show.html.erb`, `test/controllers/workshop_management/service_requests_controller_test.rb`
- **Acceptance Criteria**:
  - Scoped to current workshop
  - Status filter works
  - Tests pass

### Task 58: WM::ServiceRequestsController — accept + reject actions
- **Description**: `accept` and `reject` member PATCH actions with optimistic locking (`lock_version` in form). Rescue `ActiveRecord::StaleObjectError`.
- **Files**: `app/controllers/workshop_management/service_requests_controller.rb`, `app/views/workshop_management/service_requests/show.html.erb`
- **Acceptance Criteria**:
  - Accept transitions to `accepted`
  - Reject transitions to `rejected`
  - Stale object error handled gracefully with flash message
  - Hidden `lock_version` field in forms
  - Tests pass

### Task 59: WM::ServiceRequestsController — start action
- **Description**: `start` member PATCH action. Transitions accepted request to `in_progress`. Uses optimistic locking.
- **Files**: `app/controllers/workshop_management/service_requests_controller.rb`
- **Acceptance Criteria**:
  - Only accepted requests can be started
  - Transitions to `in_progress`
  - Stale object error handled
  - Tests pass

---

## Phase 11 — Service Records

### Task 60: Create ServiceRecord model + migration
- **Description**: Create `service_records` table: `service_request_id` (fk, unique index), `summary` (text, not null), `recommendations` (text), `performed_by` (string), `odometer_at_service` (int), `parts_used` (jsonb), `labor_cost` (decimal 10,2), `parts_cost` (decimal 10,2), `currency` (string, default "UAH"), `next_service_at_km` (int), `next_service_at_date` (date), `completed_at` (datetime, not null).
- **Files**: `db/migrate/xxx_create_service_records.rb`, `app/models/service_record.rb`, `test/models/service_record_test.rb`, `test/fixtures/service_records.yml`
- **Acceptance Criteria**:
  - Unique index on `service_request_id` (one record per request)
  - Validations: summary, completed_at required
  - `completed_at` defaults to `Time.current` on create
  - `total_cost` method returns sum of labor + parts cost
  - Tests pass

### Task 61: ServiceRecord — update car odometer callback
- **Description**: `after_create :update_car_odometer` — if `odometer_at_service` present, update `car.odometer`.
- **Files**: `app/models/service_record.rb`, `test/models/service_record_test.rb`
- **Acceptance Criteria**:
  - Creating record with odometer updates car
  - Creating record without odometer does not touch car
  - Tests pass

### Task 62: WM::ServiceRecordsController — new + create
- **Description**: `new`: loads in_progress request, pre-fills odometer. `create`: saves record, transitions request to `completed`.
- **Files**: `app/controllers/workshop_management/service_records_controller.rb`, `app/views/workshop_management/service_records/new.html.erb`, `test/controllers/workshop_management/service_records_controller_test.rb`
- **Acceptance Criteria**:
  - Only in_progress requests can get a record
  - Form: summary, parts_used, costs, odometer, recommendations, next service fields
  - Creating record transitions request to completed
  - Tests pass

### Task 63: Car show — service history display
- **Description**: Update `cars/show.html.erb` to display full service history table: date, workshop, category, odometer, summary, parts, cost, next service recommendation.
- **Files**: `app/views/cars/show.html.erb`
- **Acceptance Criteria**:
  - History table shows all completed service records for this car
  - Sorted by date descending
  - Shows "No service history yet" when empty

---

## Phase 12 — Queue System

### Task 64: Create Queue model + migration
- **Description**: Create `queues` table: `workshop_id` (fk), `service_category_id` (fk, nullable), `date` (date, not null), `status` (int, default 0). Unique index on `[workshop_id, service_category_id, date]`.
- **Files**: `db/migrate/xxx_create_queues.rb`, `app/models/queue.rb`, `test/models/queue_test.rb`, `test/fixtures/queues.yml`
- **Acceptance Criteria**:
  - Enum: `{ open: 0, paused: 1, closed: 2 }`
  - Scope: `today`
  - `next_position` returns max position + 1
  - Composite unique index enforced
  - Tests pass

### Task 65: Create QueueEntry model + migration
- **Description**: Create `queue_entries` table: `queue_id` (fk), `user_id` (fk), `car_id` (fk, nullable), `position` (int, not null), `status` (int, default 0), `estimated_wait_minutes` (int), `joined_at` (datetime, not null), `called_at` (datetime), `lock_version` (int, default 0). Unique index on `[queue_id, position]`. Partial unique index on `[queue_id, user_id]` where status in (0,1,2).
- **Files**: `db/migrate/xxx_create_queue_entries.rb`, `app/models/queue_entry.rb`, `test/models/queue_entry_test.rb`, `test/fixtures/queue_entries.yml`
- **Acceptance Criteria**:
  - Enum: `{ waiting: 0, called: 1, in_service: 2, completed: 3, no_show: 4 }`
  - No duplicate active entries per user per queue
  - Position unique within queue
  - Tests pass

### Task 66: QueueEntry — wait estimate calculation
- **Description**: `after_create :recompute_wait_estimates` — calculates `estimated_wait_minutes` for all waiting entries based on position and `estimated_duration_minutes` from service category. Fallback: 30 min.
- **Files**: `app/models/queue_entry.rb`, `test/models/queue_entry_test.rb`
- **Acceptance Criteria**:
  - Wait estimate = sum of durations for entries ahead
  - Uses 30 min default when duration not set
  - Recalculates for all waiting entries
  - Tests pass

### Task 67: QueueEntriesController — driver joins queue
- **Description**: `create` action: driver joins an open queue. Creates QueueEntry with next position, joined_at, optional car_id.
- **Files**: `app/controllers/queue_entries_controller.rb`, `app/views/queue_entries/show.html.erb`, `config/routes.rb`, `test/controllers/queue_entries_controller_test.rb`
- **Acceptance Criteria**:
  - Can only join open queues
  - Cannot join same queue twice (active)
  - Position assigned sequentially
  - Show page displays position + estimated wait
  - Tests pass

### Task 68: "Join Queue" button on Workshop show
- **Description**: Add "Стати в чергу" button on workshop show if there's an open queue today for any service category.
- **Files**: `app/views/workshops/show.html.erb`
- **Acceptance Criteria**:
  - Button visible only when open queue exists for today
  - Links to queue entry create
  - Not visible when no open queues

### Task 69: WM::QueuesController — index + show
- **Description**: `index`: today's queues for this workshop. `show`: live entry list (position, status, car, wait).
- **Files**: `app/controllers/workshop_management/queues_controller.rb`, `app/views/workshop_management/queues/index.html.erb`, `app/views/workshop_management/queues/show.html.erb`, `test/controllers/workshop_management/queues_controller_test.rb`
- **Acceptance Criteria**:
  - Scoped to current workshop
  - Shows queue status and entries
  - Tests pass

### Task 70: WM::QueuesController — open/pause/close actions
- **Description**: `open` (creates or opens today's queue), `pause`, `close` member PATCH actions.
- **Files**: `app/controllers/workshop_management/queues_controller.rb`
- **Acceptance Criteria**:
  - Open: creates queue if not exists, or reopens paused
  - Pause: only open queues
  - Close: open or paused queues
  - Tests pass

### Task 71: WM::QueueEntriesController — call + serve actions
- **Description**: `call` (waiting → called, sets called_at) and `serve` (called → in_service) member PATCH actions with optimistic locking.
- **Files**: `app/controllers/workshop_management/queue_entries_controller.rb`, `test/controllers/workshop_management/queue_entries_controller_test.rb`
- **Acceptance Criteria**:
  - Call transitions to called, recalculates wait estimates
  - Serve transitions to in_service
  - Stale object error handled
  - Tests pass

### Task 72: WM::QueueEntriesController — complete + no_show actions
- **Description**: `complete` (in_service → completed) and `no_show` (called → no_show) member PATCH actions. Both recalculate wait estimates.
- **Files**: `app/controllers/workshop_management/queue_entries_controller.rb`
- **Acceptance Criteria**:
  - Complete transitions to completed
  - No_show transitions to no_show and recalculates
  - Tests pass

### Task 73: Queue Turbo Stream broadcasts
- **Description**: Add `after_update_commit` on QueueEntry to broadcast replace via Turbo Streams to `queue_#{queue.id}`. Driver-facing show page subscribes to stream.
- **Files**: `app/models/queue_entry.rb`, `app/views/queue_entries/show.html.erb`
- **Acceptance Criteria**:
  - Status change broadcasts to queue channel
  - Driver sees live position updates without reload
  - Uses `turbo_stream_from` helper in view

### Task 74: Seed sample queues
- **Description**: Update seeds to create one open queue per seeded workshop for today's date with a few sample entries.
- **Files**: `db/seeds.rb`
- **Acceptance Criteria**:
  - Seeds create queue records
  - Each queue has 2-3 sample entries

---

## Phase 13 — Dashboard + Navigation

### Task 75: Update application layout navigation
- **Description**: Update `app/views/layouts/application.html.erb` nav: Browse Workshops, My Cars, My Requests, My Workshops (if manages any), Sign out.
- **Files**: `app/views/layouts/application.html.erb`
- **Acceptance Criteria**:
  - All nav items link correctly
  - "My Workshops" only visible to users who manage at least one workshop
  - Ukrainian labels

### Task 76: Enhanced dashboard
- **Description**: Update `DashboardController#index`: show My Workshops card (if applicable), My Cars summary, recent service requests, "Find a Workshop" CTA.
- **Files**: `app/controllers/dashboard_controller.rb`, `app/views/dashboard/index.html.erb`
- **Acceptance Criteria**:
  - Dashboard shows relevant sections based on user context
  - No role-based redirects — all users see the same dashboard with contextual content

### Task 77: Add locales for all new UI strings
- **Description**: Add all new Ukrainian (`uk.yml`) and English (`en.yml`) translations for models, views, flash messages, navigation items added across all phases.
- **Files**: `config/locales/en.yml`, `config/locales/uk.yml`
- **Acceptance Criteria**:
  - No hardcoded strings in views (all use `t()`)
  - Both locale files have matching keys
  - Ukrainian is primary UI language

---

## Dependency Graph

```
Phase 1 (Tasks 1-6): User Roles + Admin
    ↓
Phase 2 (Tasks 7-11): Workshop Operators + Status
    ↓
Phase 3 (Tasks 12-20): Service Categories + Pricing
    ↓
Phase 4 (Tasks 21-26): Admin Workshop Management ←── depends on Phase 1 + 2
    ↓
Phase 5 (Tasks 27-32): Workshop Self-Registration ←── depends on Phase 2 + 3
    ↓
Phase 6 (Tasks 33-36): Workshop Management Layout ←── depends on Phase 2
    ↓
Phase 7 (Tasks 37-42): Car Model ←── depends on Phase 1
    ↓
Phase 8 (Tasks 43-50): Car Transfers ←── depends on Phase 7
    ↓
Phase 9 (Tasks 51-56): Service Requests (Driver) ←── depends on Phase 3 + 7
    ↓
Phase 10 (Tasks 57-59): WM Request Handling ←── depends on Phase 6 + 9
    ↓
Phase 11 (Tasks 60-63): Service Records ←── depends on Phase 10
    ↓
Phase 12 (Tasks 64-74): Queue System ←── depends on Phase 6
    ↓
Phase 13 (Tasks 75-77): Dashboard + Nav ←── depends on all above
```

### Parallelizable Phases
- **Phase 4 + Phase 5 + Phase 6** can run in parallel (all depend on Phase 2)
- **Phase 7** can start as soon as Phase 1 is done (parallel with Phase 3-6)
- **Phase 8** can run in parallel with Phase 9 (both depend on Phase 7, but not on each other)
- **Phase 12** can start as soon as Phase 6 is done (parallel with Phase 9-11)
