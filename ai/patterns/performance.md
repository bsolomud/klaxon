# Pattern: Performance & Scalability

## Rules

1. **Set-based writes over per-record loops.** Prefer `insert_all` / `upsert_all` / `update_all` to `collection.each { |r| r.save/update/create/destroy }`. One statement, not N round-trips.
2. **Eager-load to kill N+1.** When a loop or view touches an association, load it with `includes` / `preload` / `eager_load`. A `.map { |x| x.assoc.field }` over unloaded records is N+1.
3. **`find_each` / `in_batches` for large scans.** Never load an unbounded table into memory. Iterate in batches; write in bulk after the batch.
4. **Index what you filter, sort, or join on.** Any column used in `where` / `order` / a join on a non-trivial table needs an index; use composite indexes for multi-column filters/sorts (see `ai/patterns/data_integrity.md`).
5. **`counter_cache` / cached aggregates over per-row counts.** Don't run a `COUNT` per row in a list.
6. **Design single-record methods so they can go bulk.** A method that acts on one record should be shaped to also act on a relation (accept a scope, build rows) — open for extension to bulk without a rewrite. This is the headline extensibility rule.
7. **Bulk methods skip validations AND callbacks.** This is the crucial trade-off. When a per-record callback maintains an invariant (delivery fan-out, Turbo broadcasts, append-only audit, `after_create` side effects), you must **re-create that side effect explicitly** after the bulk write (enqueue a job over the inserted ids) — never silently drop it. If the callback is essential and N is small and bounded, keeping the loop is acceptable; say so.
8. **Move N external calls out of the request cycle.** Web push, SMS, email, geocoding — batch where the provider allows, otherwise enqueue a job (SolidQueue). Never block a request on a loop of network calls.
9. **Batch real-time broadcasts.** Prefer one broadcast that re-renders a collection over one broadcast per sibling row when the volume is high.
10. **Measure, don't guess.** Watch the dev log for repeated identical queries (N+1) and per-row `UPDATE`/`INSERT` in a single request; those are the flags a reviewer catches.

---

## Bulk primitives

```ruby
Model.insert_all(rows)                       # one INSERT; skips validations + callbacks
Model.insert_all(rows, returning: %w[id])    # get the new ids back to trigger side effects
Model.upsert_all(rows, unique_by: :index)    # insert-or-update in one statement
scope.update_all(column: value)              # one UPDATE; skips validations + callbacks
scope.includes(:assoc).find_each { ... }     # batched read, associations preloaded
```

---

## Do / Don't

### Fan-out notifications to many recipients

`app/controllers/concerns/notification_dispatch.rb` creates one row per recipient in a loop:

```ruby
# DON'T — N inserts, one per recipient
Array(recipients).each do |recipient|
  Notification.create!(user: recipient, notifiable: notifiable, event: event)
end

# DO — one INSERT, then trigger the delivery side effect explicitly
now = Time.current
rows = Array(recipients).map do |r|
  { user_id: r.is_a?(Integer) ? r : r.id,
    notifiable_type: notifiable.class.name, notifiable_id: notifiable.id,
    event: Notification.events[event], created_at: now, updated_at: now }
end
ids = Notification.insert_all(rows, returning: %w[id]).rows.flatten if rows.any?
# Notification's after_create_commit (push/SMS fan-out) does NOT fire on insert_all,
# so re-create it: DeliverNotificationJob.perform_later(id) for each returned id.
```

> The `returning:` + explicit-job step is Rule 7 in action: the bulk write is the optimization, but the notification's delivery callback is an invariant, so you re-fire it deliberately.

### Recompute per-row values

`app/models/queue_entry.rb#recompute_wait_estimates` updates each waiting entry individually:

```ruby
# DON'T — N UPDATEs
queue.queue_entries.waiting.order(:position).each_with_index do |entry, i|
  wait = i < free ? 0 : (((i - free) / bays) + 1) * duration
  entry.update_column(:estimated_wait_minutes, wait)
end

# DO — one UPDATE with a computed CASE (ids + waits are integers → safe to inline)
ids = queue.queue_entries.waiting.order(:position).pluck(:id)
whens = ids.each_with_index.map do |id, i|
  wait = i < free ? 0 : (((i - free) / bays) + 1) * duration
  "WHEN #{id.to_i} THEN #{wait.to_i}"
end
queue.queue_entries.where(id: ids)
     .update_all(Arel.sql("estimated_wait_minutes = CASE id #{whens.join(' ')} END")) if whens.any?
```

### Scan-then-write in a job (also fixes an N+1)

`app/jobs/service_reminder_job.rb` creates + updates per record, and `record.car.user` is an N+1:

```ruby
# DON'T — N+1 on record.car.user, plus N inserts + N updates
ServiceRecord.where(reminder_sent_at: nil)
  .where(next_service_at_date: ..Date.current).find_each do |record|
  Notification.create!(user: record.car.user, notifiable: record, event: :service_due_reminder)
  record.update_column(:reminder_sent_at, Time.current)
end

# DO — eager-load the car, one bulk insert, one bulk update
due = ServiceRecord.where(reminder_sent_at: nil)
        .where(next_service_at_date: ..Date.current).includes(:car).to_a
rows = due.map do |r|
  { user_id: r.car.user_id, notifiable_type: "ServiceRecord", notifiable_id: r.id,
    event: Notification.events[:service_due_reminder], created_at: Time.current, updated_at: Time.current }
end
Notification.insert_all(rows) if rows.any?                        # + enqueue delivery per Rule 7
ServiceRecord.where(id: due.map(&:id)).update_all(reminder_sent_at: Time.current)
```

### External I/O per item — batch or defer, don't block

`app/services/web_push_deliverer.rb` and `QueueEntry#broadcast_sibling_wait_estimates` loop over `find_each` doing network / ActionCable work per item. The DB cost is already avoided; keep such loops **inside a background job** (they are), and collapse multiple broadcasts per row into a single collection re-render where volume warrants.

---

## Anti-Patterns

- **Per-row DB writes inside a request cycle.** `each { update }` / `each { create }` on anything unbounded — move to `update_all` / `insert_all` (or a job).
- **N+1 in list views and loops.** Touching `record.association` without `includes` on the driving query.
- **Unindexed `where` / `order`.** New filter/sort columns with no index; multi-column filters with no composite index.
- **Silently swapping `create!`/`update!` for bulk methods that maintain invariants.** Dropping the delivery/broadcast/audit callback to "make it fast" corrupts behavior — re-fire the side effect (Rule 7).
- **Loading whole tables into memory.** `Model.all.each` instead of `find_each` / `in_batches`.
- **Blocking a request on N network calls.** Geocoding/push/SMS/email loops belong in jobs.
