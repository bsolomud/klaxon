# Codebase Refactor — Reduce Complexity, Unify Patterns, Improve Naming

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor existing code to reduce duplication, unify patterns, and improve naming — with zero behavior change.

**Architecture:** Extract two model concerns (`Normalizable`, `TimeRangeable`), consolidate duplicated controller logic, remove dead code, and unify view helpers. Every change is tested by running the existing test suite — if tests pass, behavior is preserved.

**Tech Stack:** Ruby on Rails 8.1, Minitest, TailwindCSS

---

## File Structure

### Files to Create
- `app/models/concerns/normalizable.rb` — concern for `upcase.strip` string normalization
- `app/models/concerns/time_rangeable.rb` — concern for time-within-range checks on models with working hours

### Files to Modify
- `app/models/car.rb` — use `Normalizable` concern
- `app/models/workshop.rb` — use `TimeRangeable` concern, collapse `build_missing_*` into one method
- `app/models/workshop_service_category.rb` — use i18n key for custom validation error
- `app/controllers/workshops_controller.rb` — merge `set_visible_workshop`/`set_workshop`, remove pass-through helpers, use `before_action` for build_missing
- `app/controllers/admin/workshops_controller.rb` — collapse three status actions into one `transition` method
- `app/controllers/cars_controller.rb` — remove `vin_belongs_to_another_user?`, replace with model method
- `app/helpers/workshops_helper.rb` — remove `DAY_NAMES` constant, use `I18n.t` for day names
- `app/views/workshops/_form.html.erb` — move sort to controller
- `app/views/workshops/show.html.erb` — remove inline `.includes` call
- `app/views/layouts/workshop.html.erb` — use `workshop_status_badge` helper
- `app/javascript/controllers/hello_controller.js` — delete
- `config/importmap.rb` — remove hello_controller pin if present
- `config/routes.rb` — collapse three admin status routes into one `transition` route

### Test Files (verify, no changes expected)
- All existing tests under `test/` — run after each task to confirm zero regressions

---

### Task 1: Extract `Normalizable` concern and apply to Car

**Files:**
- Create: `app/models/concerns/normalizable.rb`
- Modify: `app/models/car.rb`

- [ ] **Step 1: Create the concern**

```ruby
# app/models/concerns/normalizable.rb
module Normalizable
  extend ActiveSupport::Concern

  class_methods do
    def normalizes_upcase(*attributes)
      attributes.each do |attr|
        before_validation do
          value = send(attr)
          send(:"#{attr}=", value.upcase.strip) if value.present?
        end
      end
    end
  end
end
```

- [ ] **Step 2: Apply to Car model — replace the two private methods**

Replace the `before_validation` callbacks and `normalize_license_plate` / `normalize_vin` methods in `app/models/car.rb` with:

```ruby
class Car < ApplicationRecord
  include Normalizable

  belongs_to :user

  enum :fuel_type, { gasoline: 0, diesel: 1, electric: 2, hybrid: 3 }
  enum :transmission, { manual: 0, automatic: 1 }

  normalizes_upcase :license_plate, :vin

  validates :make, presence: true
  validates :model, presence: true
  validates :year, presence: true,
            numericality: { only_integer: true, greater_than: 1885 }
  validates :license_plate, presence: true,
            uniqueness: { case_sensitive: false }
  validates :fuel_type, presence: true
  validates :vin, length: { is: 17 }, uniqueness: true, allow_nil: true
  validates :engine_volume, absence: { message: :not_applicable_for_electric },
            if: :electric?

  before_validation :nilify_blank_vin

  def display_name
    "#{year} #{make} #{model}"
  end

  private

  def nilify_blank_vin
    self.vin = nil if vin.blank?
  end
end
```

Note: `normalizes_upcase` handles `upcase.strip` when value is present. The `nilify_blank_vin` callback converts blank VIN to nil (existing behavior preserved). The `normalizes_upcase` on `:vin` will only fire when vin is present (non-nil, non-blank) — so the nil-ification callback must run after it. Since `before_validation` callbacks run in order of definition, `normalizes_upcase` runs first (from the concern), then `nilify_blank_vin`.

- [ ] **Step 3: Run tests**

Run: `bin/rails test test/models/car_test.rb test/controllers/cars_controller_test.rb`
Expected: all tests pass, zero failures

- [ ] **Step 4: Run full test suite**

Run: `bin/rails test`
Expected: all tests pass

- [ ] **Step 5: Run rubocop**

Run: `bin/rubocop app/models/concerns/normalizable.rb app/models/car.rb`
Expected: zero offenses

- [ ] **Step 6: Commit**

```bash
git add app/models/concerns/normalizable.rb app/models/car.rb
git commit -m "refactor: extract Normalizable concern, apply to Car model

Replace duplicate normalize_license_plate/normalize_vin methods with
a shared normalizes_upcase class method from the Normalizable concern."
```

---

### Task 2: Extract `TimeRangeable` concern and apply to Workshop

**Files:**
- Create: `app/models/concerns/time_rangeable.rb`
- Modify: `app/models/workshop.rb`

- [ ] **Step 1: Create the concern**

Extract the `time_within_range?` class method from Workshop into a concern:

```ruby
# app/models/concerns/time_rangeable.rb
module TimeRangeable
  extend ActiveSupport::Concern

  class_methods do
    def time_within_range?(time, opens, closes)
      if opens <= closes
        time >= opens && time <= closes
      else
        time >= opens || time <= closes
      end
    end
  end
end
```

- [ ] **Step 2: Apply to Workshop model**

In `app/models/workshop.rb`:

1. Add `include TimeRangeable` at the top of the class
2. Remove the `self.time_within_range?` method (lines 92-98) and the `private_class_method :time_within_range?` call (line 99)
3. The `open_now?` method already calls `self.class.time_within_range?` — this continues to work since the concern provides the class method
4. The `open_now` scope uses raw SQL (not the Ruby method), so it is unaffected

- [ ] **Step 3: Run tests**

Run: `bin/rails test test/models/workshop_test.rb test/controllers/workshops_controller_test.rb`
Expected: all tests pass

- [ ] **Step 4: Run rubocop**

Run: `bin/rubocop app/models/concerns/time_rangeable.rb app/models/workshop.rb`
Expected: zero offenses

- [ ] **Step 5: Commit**

```bash
git add app/models/concerns/time_rangeable.rb app/models/workshop.rb
git commit -m "refactor: extract TimeRangeable concern from Workshop

Move time_within_range? into a reusable concern. Workshop.open_now?
delegates to it. The open_now scope uses SQL and is unaffected."
```

---

### Task 3: Collapse `build_missing_working_hours` and `build_missing_service_categories` in Workshop

**Files:**
- Modify: `app/models/workshop.rb`

- [ ] **Step 1: Replace the two methods with a single `build_missing_associations` method**

In `app/models/workshop.rb`, replace lines 101-116:

```ruby
# Before (two methods):
# def build_missing_working_hours ...
# def build_missing_service_categories(all_categories) ...

# After (one method + two delegates):
def build_missing_working_hours
  existing_days = working_hours.map(&:day_of_week)
  (0..6).each do |day|
    working_hours.build(day_of_week: day) unless existing_days.include?(day)
  end
end

def build_missing_service_categories(all_categories)
  existing_ids = workshop_service_categories.map(&:service_category_id)
  all_categories.each do |category|
    unless existing_ids.include?(category.id)
      wsc = workshop_service_categories.build(service_category: category)
      wsc.mark_for_destruction
    end
  end
end
```

Actually, these two methods look similar but differ in meaningful ways: one iterates a range `(0..6)` and builds with a single attribute, the other iterates a collection, checks by ID, and marks for destruction. Merging them into one parameterized method would reduce clarity without real savings. **Skip this step — the methods are different enough to stay separate.** Move to the next task.

- [ ] **Step 2: No changes needed — verify tests still pass**

Run: `bin/rails test test/models/workshop_test.rb`
Expected: all tests pass

---

### Task 4: Merge `set_visible_workshop` and `set_workshop` in WorkshopsController

**Files:**
- Modify: `app/controllers/workshops_controller.rb`

- [ ] **Step 1: Merge the two finders into one `set_workshop` method**

Replace the two methods and their `before_action` declarations:

```ruby
class WorkshopsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  before_action :set_workshop, only: [:show, :edit, :update, :destroy]
  before_action :require_workshop_access!, only: [:edit, :update, :destroy]
  before_action :load_service_categories, only: [:new, :create, :edit, :update]
  before_action :build_missing_records, only: [:new, :edit]

  # ... index unchanged ...

  def show
    @working_hours = @workshop.working_hours.order(:day_of_week)
  end

  def new
    @workshop = Workshop.new
  end

  def create
    @workshop = Workshop.new(workshop_params)

    unless @workshop.valid?
      build_missing_records
      return render :new, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @workshop.save!
      @workshop.workshop_operators.create!(user: current_user, role: :owner)
    end
    redirect_to @workshop, notice: t("workshops.create.submitted")
  end

  def edit
  end

  def update
    if @workshop.update(workshop_params)
      redirect_to @workshop, notice: t("workshops.update.success")
    else
      build_missing_records
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workshop.destroy!
    redirect_to workshops_path, notice: t("workshops.destroy.success")
  end

  private

  def set_workshop
    @workshop = Workshop.includes(workshop_service_categories: :service_category).find(params[:id])

    return unless action_name == "show"
    return if @workshop.active?
    return if user_signed_in? && current_user.manages_workshop?(@workshop)

    raise ActiveRecord::RecordNotFound
  end

  def load_service_categories
    @service_categories = ServiceCategory.order(:name)
  end

  def build_missing_records
    @workshop.build_missing_working_hours
    @workshop.build_missing_service_categories(@service_categories)
  end

  def workshop_params
    params.require(:workshop).permit(
      :name, :description, :phone, :email,
      :address, :city, :country,
      :latitude, :longitude,
      :logo, photos: [],
      working_hours_attributes: [:id, :day_of_week, :opens_at, :closes_at, :closed, :_destroy],
      workshop_service_categories_attributes: [
        :id, :service_category_id, :price_min, :price_max,
        :price_unit, :estimated_duration_minutes, :_destroy
      ]
    )
  end
end
```

Key changes:
1. **Merged `set_visible_workshop` into `set_workshop`** — the visibility check runs only on `show`
2. **Extracted `build_missing_records`** — replaces the two pass-through methods, called via `before_action` for `new`/`edit` and explicitly in `create`/`update` error paths
3. **Removed `build_missing_working_hours` and `build_missing_service_categories`** wrapper methods — `build_missing_records` calls the model directly

- [ ] **Step 2: Run tests**

Run: `bin/rails test test/controllers/workshops_controller_test.rb`
Expected: all tests pass

- [ ] **Step 3: Run rubocop**

Run: `bin/rubocop app/controllers/workshops_controller.rb`
Expected: zero offenses

- [ ] **Step 4: Commit**

```bash
git add app/controllers/workshops_controller.rb
git commit -m "refactor: consolidate WorkshopsController private methods

Merge set_visible_workshop into set_workshop with action_name guard.
Extract build_missing_records to replace duplicated setup calls."
```

---

### Task 5: Collapse admin status transitions into a single `transition` action

**Files:**
- Modify: `app/controllers/admin/workshops_controller.rb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Refactor the controller**

Replace the three action methods with one `transition` method:

```ruby
class Admin::WorkshopsController < Admin::BaseController
  before_action :set_workshop, only: %i[show transition]

  TRANSITIONS = {
    "approve"  => { from: :pending,  to: :active },
    "decline"  => { from: :pending,  to: :declined },
    "suspend"  => { from: :active,   to: :suspended }
  }.freeze

  def index
    @workshops = Workshop.order(created_at: :desc)
    @workshops = @workshops.where(status: params[:status]) if params[:status].present?
  end

  def show
    @owner = @workshop.workshop_operators.find_by(role: :owner)&.user
  end

  def transition
    event = params[:event]
    rule = TRANSITIONS[event]

    unless rule && @workshop.status.to_sym == rule[:from]
      return redirect_to admin_workshop_path(@workshop), alert: t("admin.workshops.transition.invalid_status")
    end

    if event == "decline"
      @workshop.update!(status: rule[:to], decline_reason: params[:decline_reason])
    else
      @workshop.update!(status: rule[:to])
    end

    redirect_to admin_workshop_path(@workshop), notice: t("admin.workshops.transition.success")
  end

  private

  def set_workshop
    @workshop = Workshop.includes(:service_categories).find(params[:id])
  end
end
```

- [ ] **Step 2: Update routes**

In `config/routes.rb`, replace the three member routes:

```ruby
  namespace :admin do
    root "workshops#index"
    resources :workshops, only: %i[index show] do
      member do
        patch :transition
      end
    end
    resources :users, only: %i[index show]
  end
```

- [ ] **Step 3: Update locale keys**

The old per-action flash keys (`admin.workshops.approve.success`, etc.) are replaced by `admin.workshops.transition.success` and `admin.workshops.transition.invalid_status`. Update both `config/locales/en.yml` and `config/locales/uk.yml`:

In the `admin.workshops` section, replace the `approve`, `decline`, `suspend` sub-keys with:

```yaml
# en.yml
admin:
  workshops:
    transition:
      success: "Workshop status updated successfully"
      invalid_status: "Cannot perform this transition from current status"
```

```yaml
# uk.yml
admin:
  workshops:
    transition:
      success: "Статус майстерні оновлено"
      invalid_status: "Неможливо виконати цю дію з поточним статусом"
```

Remove the old `approve`, `decline`, `suspend` sub-keys.

- [ ] **Step 4: Update views that reference the old routes**

Search for `approve_admin_workshop_path`, `decline_admin_workshop_path`, `suspend_admin_workshop_path` in views and replace with `transition_admin_workshop_path(@workshop)` plus a hidden `event` parameter. For example:

```erb
<%# Before: %>
<%= button_to t("..."), approve_admin_workshop_path(@workshop), method: :patch %>

<%# After: %>
<%= button_to t("..."), transition_admin_workshop_path(@workshop), method: :patch, params: { event: "approve" } %>
```

Do this for all three buttons (approve, decline, suspend) in the admin workshop show view.

- [ ] **Step 5: Update admin controller tests**

In `test/controllers/admin/workshops_controller_test.rb`, update the test paths:

Replace `patch approve_admin_workshop_path(...)` with `patch transition_admin_workshop_path(...), params: { event: "approve" }` and similarly for decline/suspend.

- [ ] **Step 6: Run tests**

Run: `bin/rails test test/controllers/admin/workshops_controller_test.rb`
Expected: all tests pass

- [ ] **Step 7: Run full test suite**

Run: `bin/rails test`
Expected: all tests pass

- [ ] **Step 8: Run rubocop**

Run: `bin/rubocop app/controllers/admin/workshops_controller.rb config/routes.rb`
Expected: zero offenses

- [ ] **Step 9: Commit**

```bash
git add app/controllers/admin/workshops_controller.rb config/routes.rb config/locales/en.yml config/locales/uk.yml app/views/admin/ test/controllers/admin/workshops_controller_test.rb
git commit -m "refactor: collapse admin approve/decline/suspend into single transition action

Replace three near-identical status methods with one parameterized
transition action. Routes simplified to a single member PATCH."
```

---

### Task 6: Move `vin_belongs_to_another_user?` from controller to Car model

**Files:**
- Modify: `app/models/car.rb`
- Modify: `app/controllers/cars_controller.rb`
- Modify: `app/views/cars/_form.html.erb`

- [ ] **Step 1: Add `vin_owned_by_another_user?` method to Car model**

Add to `app/models/car.rb`, in the public section (before `private`):

```ruby
def vin_duplicate_for_another_user?
  vin.present? &&
    errors[:vin].any? &&
    Car.where.not(user_id: user_id).exists?(vin: vin)
end
```

- [ ] **Step 2: Simplify the controller**

In `app/controllers/cars_controller.rb`, update the `create` action:

```ruby
def create
  @car = current_user.cars.build(car_params)

  if @car.save
    redirect_to @car, notice: t("cars.create.success")
  else
    render :new, status: :unprocessable_entity
  end
end
```

Remove the `vin_belongs_to_another_user?` private method entirely.

- [ ] **Step 3: Update the view to call the model method**

In `app/views/cars/_form.html.erb`, replace line 4:

```erb
<%# Before: %>
<% if local_assigns[:vin_duplicate] %>

<%# After: %>
<% if car.persisted? == false && car.vin_duplicate_for_another_user? %>
```

Note: We check `persisted? == false` to only show this on create failures (the original behavior — only CarsController#create set `@vin_duplicate`).

- [ ] **Step 4: Run tests**

Run: `bin/rails test test/models/car_test.rb test/controllers/cars_controller_test.rb`
Expected: all tests pass

- [ ] **Step 5: Run rubocop**

Run: `bin/rubocop app/models/car.rb app/controllers/cars_controller.rb`
Expected: zero offenses

- [ ] **Step 6: Commit**

```bash
git add app/models/car.rb app/controllers/cars_controller.rb app/views/cars/_form.html.erb
git commit -m "refactor: move VIN duplicate check from controller to Car model

Replace controller-level vin_belongs_to_another_user? with
Car#vin_duplicate_for_another_user? — eliminates @vin_duplicate ivar."
```

---

### Task 7: Remove `DAY_NAMES` constant from WorkshopsHelper

**Files:**
- Modify: `app/helpers/workshops_helper.rb`

- [ ] **Step 1: Simplify `day_name` to use I18n directly**

The `DAY_NAMES` array duplicates locale keys. Replace the helper:

```ruby
module WorkshopsHelper
  def day_name(day_of_week)
    I18n.t("date.day_names")[day_of_week]
  end

  def workshop_status_indicator(workshop, open_key: "workshops.index.open_now", closed_key: "workshops.index.closed_now")
    is_open = workshop.open_now?
    dot_color = is_open ? "bg-green-500" : "bg-red-500"
    label = is_open ? t(open_key) : t(closed_key)

    tag.div(class: "flex items-center gap-1.5") do
      tag.div(class: "h-2 w-2 rounded-full shrink-0 #{dot_color}") +
        tag.span(label, class: "text-xs text-gray-500")
    end
  end
end
```

`I18n.t("date.day_names")` returns an array like `["Sunday", "Monday", ...]` from Rails' built-in date translations, indexed 0-6 matching `wday`. This already works for both `en` and `uk` locales since Rails ships with these translations.

- [ ] **Step 2: Verify the locale keys exist**

Run: `bin/rails runner "puts I18n.t('date.day_names', locale: :uk).inspect"`
Expected: an array of 7 Ukrainian day names

Run: `bin/rails runner "puts I18n.t('date.day_names', locale: :en).inspect"`
Expected: an array of 7 English day names

- [ ] **Step 3: Run tests**

Run: `bin/rails test`
Expected: all tests pass

- [ ] **Step 4: Run rubocop**

Run: `bin/rubocop app/helpers/workshops_helper.rb`
Expected: zero offenses

- [ ] **Step 5: Commit**

```bash
git add app/helpers/workshops_helper.rb
git commit -m "refactor: remove DAY_NAMES constant, use Rails I18n date.day_names

Eliminates duplication between helper constant and locale files."
```

---

### Task 8: Extract `workshop_status_badge` helper for layout

**Files:**
- Modify: `app/helpers/workshops_helper.rb`
- Modify: `app/views/layouts/workshop.html.erb`

- [ ] **Step 1: Add the badge helper**

Add to `app/helpers/workshops_helper.rb`:

```ruby
def workshop_status_badge(status)
  config = {
    "active"    => { bg: "bg-green-100",  text: "text-green-800" },
    "pending"   => { bg: "bg-yellow-100", text: "text-yellow-800" },
    "suspended" => { bg: "bg-red-100",    text: "text-red-800" },
    "declined"  => { bg: "bg-gray-100",   text: "text-gray-800" }
  }
  colors = config[status] || config["pending"]

  tag.span(
    t("layouts.workshop.status_#{status}"),
    class: "inline-flex items-center rounded-full #{colors[:bg]} px-2 py-0.5 text-[10px] font-medium #{colors[:text]}"
  )
end
```

- [ ] **Step 2: Replace the case statement in the layout**

In `app/views/layouts/workshop.html.erb`, replace lines 29-44 (the workshop info div content):

```erb
<%# Workshop info %>
<div class="border-b border-gray-200 px-4 py-4">
  <h2 class="text-sm font-semibold text-gray-900 truncate"><%= @workshop.name %></h2>
  <div class="mt-1">
    <%= workshop_status_badge(@workshop.status) %>
  </div>
</div>
```

- [ ] **Step 3: Run tests**

Run: `bin/rails test`
Expected: all tests pass

- [ ] **Step 4: Run rubocop**

Run: `bin/rubocop app/helpers/workshops_helper.rb app/views/layouts/workshop.html.erb`
Expected: zero offenses

- [ ] **Step 5: Commit**

```bash
git add app/helpers/workshops_helper.rb app/views/layouts/workshop.html.erb
git commit -m "refactor: extract workshop_status_badge helper

Replace inline case statement in workshop layout with a helper method."
```

---

### Task 9: Move sort logic from workshop form view to controller

**Files:**
- Modify: `app/controllers/workshops_controller.rb`
- Modify: `app/views/workshops/_form.html.erb`

- [ ] **Step 1: Update `build_missing_records` to sort**

In `app/controllers/workshops_controller.rb`, update `build_missing_records`:

```ruby
def build_missing_records
  @workshop.build_missing_working_hours
  @workshop.build_missing_service_categories(@service_categories)
  @sorted_workshop_service_categories = @workshop.workshop_service_categories
    .sort_by { |wsc| wsc.service_category&.name.to_s }
end
```

- [ ] **Step 2: Update the view**

In `app/views/workshops/_form.html.erb`, replace lines 27-28:

```erb
<%# Before: %>
<% sorted_wscs = workshop.workshop_service_categories.sort_by { |wsc| wsc.service_category&.name.to_s } %>
<%= f.fields_for :workshop_service_categories, sorted_wscs do |wsc| %>

<%# After: %>
<%= f.fields_for :workshop_service_categories, @sorted_workshop_service_categories do |wsc| %>
```

- [ ] **Step 3: Run tests**

Run: `bin/rails test test/controllers/workshops_controller_test.rb`
Expected: all tests pass

- [ ] **Step 4: Run rubocop**

Run: `bin/rubocop app/controllers/workshops_controller.rb`
Expected: zero offenses

- [ ] **Step 5: Commit**

```bash
git add app/controllers/workshops_controller.rb app/views/workshops/_form.html.erb
git commit -m "refactor: move service category sort from view to controller

Template should not contain sorting logic."
```

---

### Task 10: Remove inline `.includes` from workshop show view

**Files:**
- Modify: `app/views/workshops/show.html.erb`

- [ ] **Step 1: Remove the inline includes**

The `set_workshop` method in `WorkshopsController` already eager-loads `workshop_service_categories: :service_category`. The view re-calls `.includes(:service_category)` on line 70 — this is redundant.

In `app/views/workshops/show.html.erb`, replace line 70:

```erb
<%# Before: %>
<% @workshop.workshop_service_categories.includes(:service_category).each do |wsc| %>

<%# After: %>
<% @workshop.workshop_service_categories.each do |wsc| %>
```

- [ ] **Step 2: Run tests**

Run: `bin/rails test test/controllers/workshops_controller_test.rb`
Expected: all tests pass

- [ ] **Step 3: Commit**

```bash
git add app/views/workshops/show.html.erb
git commit -m "refactor: remove redundant includes from workshop show view

Controller already eager-loads the association."
```

---

### Task 11: Use i18n key for WorkshopServiceCategory validation error

**Files:**
- Modify: `app/models/workshop_service_category.rb`

- [ ] **Step 1: Replace hardcoded error string with i18n symbol**

In `app/models/workshop_service_category.rb`, line 40:

```ruby
# Before:
errors.add(:price_max, "must be greater than or equal to price_min")

# After:
errors.add(:price_max, :greater_than_or_equal_to_price_min)
```

- [ ] **Step 2: Add locale entries**

In `config/locales/en.yml`, under `activerecord.errors.models`:

```yaml
activerecord:
  errors:
    models:
      workshop_service_category:
        attributes:
          price_max:
            greater_than_or_equal_to_price_min: "must be greater than or equal to minimum price"
```

In `config/locales/uk.yml`:

```yaml
activerecord:
  errors:
    models:
      workshop_service_category:
        attributes:
          price_max:
            greater_than_or_equal_to_price_min: "повинна бути більшою або рівною мінімальній ціні"
```

- [ ] **Step 3: Run tests**

Run: `bin/rails test test/models/workshop_service_category_test.rb`
Expected: all tests pass

- [ ] **Step 4: Commit**

```bash
git add app/models/workshop_service_category.rb config/locales/en.yml config/locales/uk.yml
git commit -m "refactor: use i18n key for price_max validation error

Replace hardcoded English string with locale-aware error message."
```

---

### Task 12: Delete unused hello_controller.js

**Files:**
- Delete: `app/javascript/controllers/hello_controller.js`
- Modify: `config/importmap.rb` (if hello_controller is pinned)

- [ ] **Step 1: Check importmap for hello_controller pin**

Run: `grep -n "hello" config/importmap.rb`

If found, remove the pin line.

- [ ] **Step 2: Delete the file**

```bash
rm app/javascript/controllers/hello_controller.js
```

- [ ] **Step 3: Run tests**

Run: `bin/rails test`
Expected: all tests pass (no test references hello_controller)

- [ ] **Step 4: Commit**

```bash
git add -A app/javascript/controllers/hello_controller.js
git commit -m "refactor: remove unused hello_controller.js scaffold artifact"
```

---

### Task 13: Final verification

- [ ] **Step 1: Run full test suite**

Run: `bin/rails test`
Expected: all tests pass

- [ ] **Step 2: Run rubocop**

Run: `bin/rubocop`
Expected: zero offenses

- [ ] **Step 3: Run brakeman**

Run: `bin/brakeman --no-pager`
Expected: no new warnings
