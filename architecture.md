# AULABS Architecture

## Core Principles

1. **Rails conventions over abstractions.** No service objects, form objects, or interactors unless a specific problem demands it. Fat models over thin controllers. Business logic lives in models.
2. **Simplicity over flexibility.** Solve the MVP problem, not hypothetical future problems.
3. **Explicit authorization, never implicit.** Every workshop management action must pass through `require_workshop_access!`. Every admin action must authenticate via `authenticate_admin!`.
4. **Consistency over cleverness.** Every agent, every session, every PR follows the same patterns. Patterns live in `ai/patterns/`.
5. **Real-time is a feature, not an afterthought.** Queue state changes always broadcast Turbo Streams. Never poll.
6. **Append-only for audit data.** `car_transfer_events` and `car_ownership_records` are never updated or deleted.

---

## Domain Boundaries

### Three Namespaces, Three Audiences

```
/                          ApplicationController     Users (drivers + workshop managers)
/admin/                    Admin::BaseController     Platform admins (separate Devise model)
/workshop_management/      WorkshopManagement::BaseController    Workshop owners/staff
```

These namespaces never share controllers. A driver-facing action is **never** in the `workshop_management` namespace.

### Domain Objects

| Model | Belongs To | Notes |
|---|---|---|
| User | — | Single people model. Role: driver only in MVP. |
| Admin | — | Separate Devise model. Never in users table. |
| Workshop | many Users (via WorkshopOperator) | Has status lifecycle: pending → active/declined/suspended |
| WorkshopOperator | User + Workshop | Join table. role: owner/staff. Access is determined here, not on User. |
| WorkshopServiceCategory | Workshop + ServiceCategory | Pricing + duration live here, not on ServiceCategory. |
| Car | User | One owner at a time. Transfers are audited. |
| CarTransfer | Car | One active transfer per car at a time (partial unique index). |
| CarTransferEvent | CarTransfer | Append-only audit log. No `updated_at`. |
| CarOwnershipRecord | Car + User | Append-only ownership timeline. |
| ServiceRequest | Car + Workshop + WorkshopServiceCategory | Price snapshotted at create time. Optimistic locking. |
| ServiceRecord | ServiceRequest (1:1) | Append-only digital passport entry. Created only once per request. |
| Queue | Workshop + optional ServiceCategory | Date-scoped. One per workshop/category/day. |
| QueueEntry | Queue + User | Position-based. Turbo Stream broadcasts on status change. |

---

## Data Flow

### Workshop Submission → Active
```
User submits workshop (status: pending)
  → WorkshopOperator created (role: owner)
  → Admin reviews in /admin/workshops
  → Admin approves → workshop.active!
  → Owner can now access /workshop_management/workshops/:id/...
```

### Driver Books a Service
```
Driver finds active workshop via /workshops
  → Selects service category (offered by that workshop)
  → Selects their car + preferred_time
  → ServiceRequest.create! (price snapshotted, lock_version: 0)
  → Workshop operator sees it in workshop_management#index
  → Operator accepts → in_progress → creates ServiceRecord → completed
  → car.odometer updated automatically (after_create callback)
  → Driver sees full history on /cars/:id
```

### Driver Joins a Queue
```
Driver sees "Join Queue" on workshop show (if queue open today)
  → POST /queues/:queue_id/entries
  → QueueEntry created with next position
  → Turbo Stream broadcast to queue_#{queue.id}
  → Driver watches /queue_entries/:id (live position)
  → Operator calls next → entry.called! → broadcast
```

### Car Ownership Transfer
```
New user enters VIN that belongs to another user
  → System blocks creation, shows claim prompt
  → CarTransfer created (status: requested, token: random)
  → CarTransferEvent: transfer_requested
  → Email sent to current owner with token link
  → CarTransferEvent: notification_sent
  → Owner approves → car.user_id updated
  → CarOwnershipRecord: previous ended_at set, new record created
  → CarTransferEvent: approved + ownership_transferred
```

---

## Authorization Model

### Rule 1: Two separate Devise models
- `User` — drivers and workshop staff. Authenticated via `authenticate_user!` in `ApplicationController`.
- `Admin` — platform administrators. Authenticated via `authenticate_admin!` in `Admin::BaseController`.
- These models never mix. An Admin is never a User.

### Rule 2: Workshop access is per-workshop, per-user, via join table
- `current_user.manages_workshop?(@workshop)` is the single source of truth.
- This check is always performed in `WorkshopManagement::BaseController#require_workshop_access!`.
- Never check `current_user.role` to gate workshop management. Role does not determine workshop access.

### Rule 3: WorkshopManagement::BaseController always resolves workshop from params
```ruby
def set_current_workshop
  @workshop = current_user.workshops.active.find(params[:workshop_id])
end
```
- `@workshop` is always the authoritative context. No session storage.
- Finding a workshop via `current_user.workshops` implicitly scopes to workshops the user manages.

### Rule 4: Drivers own their data
- A driver's service requests are always scoped to `current_user.cars`.
- A driver cannot see another driver's cars, service requests, or service records.
- Workshop operators access requests via `@workshop.service_requests`, never via a global scope.

### Rule 5: Admins can only act on workshops, users — never impersonate
- Admin controllers skip `authenticate_user!` and set `authenticate_admin!`.
- Admin views are completely separate from user-facing views.

---

## Namespace Separation

### ApplicationController (User-facing)
- Enforces `authenticate_user!` globally.
- Provides `require_workshop_access!(workshop)` helper (used only outside the namespace for edge cases).
- Layout: `application`.

### Admin::BaseController
```ruby
class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_admin!
  skip_before_action :authenticate_user!
end
```
- All admin controllers inherit this.
- Routes live under `/admin/` namespace.
- Devise routes: `devise_for :admins, path: "admin/auth"`.

### WorkshopManagement::BaseController
```ruby
class WorkshopManagement::BaseController < ApplicationController
  layout "workshop"
  before_action :set_current_workshop
  before_action :require_workshop_access!
end
```
- All workshop management controllers inherit this.
- `@workshop` is always available and verified.
- Routes live under `/workshop_management/workshops/:workshop_id/...`.

### Driver Controllers (no namespace)
- `CarsController`, `ServiceRequestsController`, `CarTransfersController` — all inherit `ApplicationController` directly.
- Always scope queries to `current_user`.

---

## Key Constraints

- Workshop status transitions: `pending → active`, `pending → declined`, `active → suspended`. No other transitions.
- ServiceRecord is created exactly once per ServiceRequest (unique DB index on `service_request_id`).
- CarTransfer: only one active transfer per car at a time (partial unique index where status = 0).
- ServiceRequest price is snapshotted at create time via `before_create :snapshot_price`. Never re-read from WorkshopServiceCategory after creation.
- Queue position is immutable once assigned. Status moves forward only.
- Queue: one queue per workshop/service_category/date (composite unique index).
- All service request status transitions use optimistic locking (`lock_version`).
- All queue entry status transitions use optimistic locking (`lock_version`).
