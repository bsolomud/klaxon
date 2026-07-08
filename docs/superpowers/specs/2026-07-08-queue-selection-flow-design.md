# Queue Selection Flow — Design

**Date:** 2026-07-08
**Status:** Approved

## Purpose

Rework the driver-facing way of joining a service queue so that:

1. A workshop can run one live queue per service type (already supported by the
   data model; the **operator UI must be extended** to create per-service queues —
   today it can only open the anonymous "general" queue).
2. A driver taps a **single** "Стати в чергу" button that opens a picker of all
   open queues at that workshop, selects **exactly one**, and joins it.
3. After joining, the driver sees their seat (position) and approximate wait — this
   already exists on the entry page and is reused unchanged.
4. A driver can be in **only one active queue across the entire platform** at a
   time, which requires a new ability to **leave** a queue.

## Background — current state

- **`ServiceQueue`** (table `queues`): `belongs_to :workshop` + optional
  `service_category`; `date` + `status` (open/paused/closed). Unique index on
  `(workshop, service_category, date)` plus a partial unique index for the
  general (null-category) queue. The model **already** allows one queue per
  service type per day.
- **`QueueEntry`**: `belongs_to` queue + user + optional car; `position`, `status`
  (waiting/called/in_service/completed/no_show), `estimated_wait_minutes`. A
  **partial unique index** `index_queue_entries_active_user_per_queue` blocks a
  user from two active entries in the **same** queue (but permits different
  queues). Wait estimate = `position × estimated_duration_minutes`, recomputed in
  `QueueEntry#recompute_wait_estimates`. All changes broadcast live via Turbo
  Streams to `queue_<id>_drivers` and `queue_<id>_operators`.
- **Operator UI** (`workshop_management/queues`): open/pause/close + call/serve/
  complete/no_show. **Gap:** `queues/index` only shows an "Open queue" button in
  the empty state and passes **no** `service_category_id`, so through the UI an
  operator can only ever open the general queue.
- **Driver UI** (`workshops/show`): renders **one join button per open queue**,
  each of which joins immediately using `current_user.cars.first`. After joining,
  `queue_entries/show` shows position + estimated wait + status, live-updating.
- **No leave/cancel action exists** anywhere (`queue_entries` routes are only
  `show`/`create`; operators have no "remove driver" beyond `no_show`).

## Decisions

| Topic | Decision |
|---|---|
| One-queue limit | **One active queue globally** per driver (platform-wide). |
| Queues per service | **One queue per service** — keep the existing unique index. |
| Picker presentation | **Modal dialog** on the workshop page. |
| Average time in queue | **Reuse existing `estimated_duration_minutes`** (the per-service duration the workshop already sets). A dynamic, queue-derived calculation is future work. |
| Leave mechanic | **Destroy** the entry (reuses existing `after_destroy_commit :broadcast_entry_removed`). |
| Modal delivery | **Server-rendered** `<dialog>` inside `workshops/show`, toggled by a small Stimulus controller — no lazy Turbo Frame fetch. |

## Design

### 1. Model & DB — enforce "one active queue globally"

- **Migration:**
  - Drop `index_queue_entries_active_user_per_queue`.
  - Add global partial unique index on `queue_entries(user_id) WHERE status IN
    (0,1,2)` (name e.g. `index_queue_entries_active_user`). This enforces at most
    one active entry per user across all queues and subsumes the old per-queue
    constraint.
- **`QueueEntry`:** replace the `queue_id`-scoped uniqueness validation with a
  global one on `user_id`:

  ```ruby
  validates :user_id, uniqueness: {
    conditions: -> { where(status: [:waiting, :called, :in_service]) },
    message: :already_in_queue
  }
  ```

  Reuse the existing `already_in_queue` message key (currently on the `queue_id`
  validation) rather than adding a new one; its text changes from "this queue" to
  the global meaning.

  Rails excludes the current record by id on update, so operator status
  transitions (waiting → called → in_service) still validate.
- **`ServiceQueue`:** add helpers for the picker (no schema change):
  - `waiting_count` → `queue_entries.waiting.count`.
  - `prospective_wait_minutes` → `waiting_count × duration`, where `duration` is
    the workshop's `estimated_duration_minutes` for this queue's service category
    (30-minute default for the general queue, matching current recompute logic).
- **No new average-time field.** `QueueEntry#recompute_wait_estimates` is
  unchanged — it already derives wait from `estimated_duration_minutes`.

### 2. Operator — create a queue per service

Rework `workshop_management/queues/index`:

- List **each of the workshop's service categories** (via
  `@workshop.service_categories`) plus a general-queue row.
- For a category with an open queue today: show status badge + active count +
  **"Переглянути"** link.
- For a category without one: show **"Відкрити чергу"** — `button_to` the existing
  `open` action **with `service_category_id`**.
- Harden `QueuesController#open` to verify `service_category_id` is `nil` or one of
  the workshop's own category ids before find-or-create (reject otherwise).

The `open` action already accepts `service_category_id` and find-or-creates; no
new route or major controller logic is needed.

### 3. Driver — single button + modal picker

On `workshops/show`:

- Replace the N inline join buttons with **one** "Стати в чергу" button that opens
  a hidden `<dialog>` rendered on the page.
- Modal contents:
  - Radio list (single-select) of the open queues (`@open_queues`), each row:
    service name + "N в черзі · ~X хв" (from `waiting_count` /
    `prospective_wait_minutes`; show "вільно · зараз" when empty).
  - A car `<select>` (defaults to first car; car remains optional per the model).
  - Confirm button → submits to existing `queue_entries#create`
    (`queue_id` + `car_id`) → redirects to the live position page.
- New Stimulus controller (e.g. `dialog_controller.js`) using the native
  `<dialog>` element (`showModal()` / `close()`), consistent with the app's other
  small single-purpose controllers. Import-map pinned; no npm.
- **Already-in-a-queue state:** if `current_user.queue_entries.active` exists, the
  page shows a banner **"Ви вже в черзі — {workshop} · позиція N → переглянути"**
  (link to that entry) **instead of** the join button.

### 4. Global-limit backstop & leave flow

- **Backstop in `create`:** catch the unique-index violation
  (`ActiveRecord::RecordNotUnique` on the new global index) / validation failure
  and redirect with the already-in-queue message + link to the current active
  entry. Handles the multi-device / stale-page case where the UI banner wasn't
  shown. Update the existing rescue that currently matches
  `"index_queue_entries_active_user_per_queue"` to the new index name.
- **Leave action:** add `DELETE queue_entries#destroy`, scoped to
  `current_user.queue_entries` (own entry only). Destroy frees the global slot and
  the existing `after_destroy_commit :broadcast_entry_removed` clears the card from
  the operator's live view.
- **Leave UI:** **"Покинути чергу"** button on `queue_entries/show` (the position
  page) and within the already-in-queue banner/message.

### 5. i18n

Add keys to **both** `config/locales/en.yml` and `config/locales/uk.yml` (UI text
is Ukrainian):

- Modal title ("Оберіть чергу"), empty-queue label ("вільно" / "зараз"), car label.
- Confirm button.
- "Покинути чергу" + leave success flash.
- Already-in-a-queue flash (with workshop + position interpolation) and the
  updated `already_in_queue` validation-message text (both reusing the existing
  `already_in_queue` keys).
- Per-service "Відкрити чергу" / "Переглянути" on the operator index (reuse
  existing keys where present).

### 6. Testing (Minitest, under `test/`)

**Rewrite (assume today's multi-button / multi-queue behavior or the old index
name):**

- `test/system/queue_flow_test.rb`
- `test/system/live_queue_test.rb`
- `test/controllers/queue_entries_controller_test.rb`

**New / updated coverage:**

- **Model** (`queue_entry_test.rb`): a user cannot hold two active entries across
  different queues; leaving (destroy) frees the slot so a new join succeeds.
- **Controller:** `create` blocks a second active entry with the friendly redirect;
  `destroy` removes the caller's own entry only; operator `open` creates a queue
  for a specific category and rejects a foreign category.
- **System:** open modal → select one queue + car → join → see position; attempt to
  join elsewhere → see prompt → leave → join the new queue.

## Out of scope / future

- Dynamic, queue-derived average wait time (replaces the reused
  `estimated_duration_minutes` later, in the same code path).
- Multiple named lanes/bays per single service type (explicitly rejected: one
  queue per service).
- A global nav indicator of the driver's current active queue (the workshop-page
  banner is the in-scope surface).
- Changes to operator call/serve/complete/no_show mechanics or to `ServiceRequest`.
