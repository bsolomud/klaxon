# Code review — `f/add-workshops`

**Date:** 2026-08-07 · **Base:** `origin/master` · **Mode:** report

## Summary

**Verdict: approve with follow-ups.** The branch builds the full AULABS transactional
product (workshops, queues, service requests, digital passport, notifications, payments,
map discovery, onboarding) to a high standard. The automated baseline is **clean** and the
security posture is solid — no blockers. The worthwhile improvements are about **scale/
extensibility**: a handful of notification/estimate operations run one row at a time and
should become set-based writes before traffic grows, plus a couple of small DRY/readability
items.

No 🔴 blockers. Findings are 🟡 (maintainability/scale) and 🟢 (polish).

## General notes (not line-specific)

- **Tool baseline is green:** `bin/rubocop` (258 files, 0 offenses), `bin/brakeman` (0
  warnings), `bin/bundler-audit` (clean), `bin/importmap audit` (clean).
- **Scope:** 385 files vs `origin/master` — this is effectively the whole branch, including
  generated/vendored files (`vendor/javascript/leaflet.js`, `db/schema.rb`, `config/locales/*`,
  `page-captures/`). Those are not line-reviewed; this report focuses on `app/` code and the
  design as a whole.
- **Positives worth calling out** (see bottom) — the review standard is "does it improve
  overall code health", and this branch clearly does.

---

## Findings

### 🟡 Extensibility/perf — notifications created one row at a time
`app/controllers/concerns/notification_dispatch.rb:9` — used by 5+ controllers
(`service_requests`, `admin/workshops`, `workshop_management/queues`, …).

```ruby
Array(recipients).each do |recipient|
  Notification.create!(user: recipient, notifiable: notifiable, event: event)
end
```

Each recipient is a separate `INSERT`. For a workshop with many operators, or a queue-close
that notifies every waiting driver, this is N round-trips. Move to a single `insert_all` and
re-fire the delivery callback explicitly (bulk skips `after_create_commit`). Full pattern +
the callback caveat in `ai/patterns/performance.md`.

### 🟡 Perf — wait estimates updated per entry in a loop
`app/models/queue_entry.rb:44` — `recompute_wait_estimates` runs on **every** join and
status change:

```ruby
queue.queue_entries.waiting.order(:position).each_with_index do |entry, i|
  wait = i < free ? 0 : (((i - free) / bays) + 1) * duration
  entry.update_column(:estimated_wait_minutes, wait)
end
```

N `UPDATE`s on a hot path. Collapse to one `update_all` with a computed `CASE`
(ids and waits are integers → safe to inline). See `ai/patterns/performance.md`.

### 🟡 Perf — N+1 + per-row writes in the reminder job
`app/jobs/service_reminder_job.rb:12`

```ruby
.find_each do |record|
  Notification.create!(user: record.car.user, notifiable: record, event: :service_due_reminder)
  record.update_column(:reminder_sent_at, Time.current)
end
```

`record.car.user` is an N+1 across the whole due set, and it's a create + update per record.
Eager-load `:car`, `insert_all` the notifications, and one `update_all` for `reminder_sent_at`
(then enqueue delivery for the inserted ids). Rewrite in `ai/patterns/performance.md`.

### 🟡 Readability/correctness — `format_money` truncates the fractional part
`app/helpers/application_helper.rb:24`

```ruby
def format_money(amount, currency)
  "#{amount.to_i} #{currency}"
end
```

`amount.to_i` drops kopiykas: a `service_record.total_cost` of `1700.50` renders as
`"1700 UAH"`. On a payments surface that's a real (if small) correctness gap. Format the
fractional part, or round deliberately and document why:

```suggestion
  def format_money(amount, currency)
    "#{ActiveSupport::NumberHelper.number_to_delimited(amount.to_d.round(2))} #{currency}"
  end
```

### 🟢 DRY — the two Leaflet controllers duplicate map setup
`app/javascript/controllers/location_picker_controller.js:12` and
`app/javascript/controllers/map_controller.js:19` both define the same `PIN_HTML` SVG, the
same OSM `tileLayer` config, and the same `divIcon`. Extract a tiny shared module
(e.g. `app/javascript/lib/leaflet_map.js` exporting `pinIcon()` + `baseTileLayer(map)`) and
import it in both. Keeps the pin/tiles consistent and one place to change.

### 🟢 Perf (low) — per-subscription push send
`app/services/web_push_deliverer.rb:12` — `find_each { send_to }` is one HTTP call per
subscription. Fine today (it runs inside `DeliverNotificationJob`), but if push volume grows,
batch or fan out to sub-jobs (Rule 9, `ai/patterns/performance.md`).

---

## Positives (code health)

- **Clean automated baseline** — RuboCop/Brakeman/bundler-audit/importmap all green.
- **Good extension points** — the provider-agnostic `Payments` gateway (`start`/`verify_callback`/
  `refund`) and the `WebPushDeliverer` / `Sms` adapters are exactly the sanctioned
  service-object use (`ai/architecture.md`); swapping providers is a config change.
- **Security done right** — queries scoped to `current_user` / `@workshop`; `sanitize_sql_array`
  for the distance SQL; admin-gated `send_data` + `X-Content-Type-Options: nosniff` with
  content-type/size allowlists on uploads (`ai/patterns/security.md`).
- **Data integrity** — optimistic locking + transactions on state machines; append-only records
  (`ai/patterns/data_integrity.md`).
- **Tests & i18n** — thorough Minitest + system coverage; every user-facing string in both
  `uk.yml` and `en.yml`.

---

## Recommended next steps

1. Land the three 🟡 bulk/N+1 rewrites (`notification_dispatch`, `queue_entry`,
   `service_reminder_job`) — highest scale payoff, small diffs.
2. Fix `format_money` rounding before payments go live.
3. Extract the shared Leaflet module when convenient.
