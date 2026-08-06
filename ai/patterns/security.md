# Pattern: Security

Maps the OWASP Top 10:2021 (https://owasp.org/Top10/2021/) onto Rails and this repo.
Anything here is a 🔴 blocker in review. See also the Rails Security Guide
(https://guides.rubyonrails.org/security.html), `ai/patterns/authorization.md`, and
`ai/patterns/data_integrity.md`.

## Rules

1. **Scope every lookup to the authenticated principal (A01 Broken Access Control).** `current_user.cars`, `@workshop.service_requests`, `current_user.workshops.active.find(...)`. Never `Model.find(params[:id])` on user data, and never "find then manually compare owner".
2. **Parameterize all SQL (A03 Injection).** Placeholders/named binds, or `sanitize_sql_array` inside `Arel.sql`. Never `where("… #{user_input}")`, `find_by_sql` with interpolation, or interpolated `order`/`pluck`.
3. **Strong params, never `permit!` (A01).** Explicit allowlist per action. Privilege-ish attributes (`role`, status, admin flags) are set from a validated allowlist in code, not mass-assigned from the form.
4. **Never render user input raw (A03 XSS).** No `raw`, `.html_safe`, or `sanitize` on user-supplied strings — rely on ERB auto-escaping. `html_safe` is only for markup you fully control.
5. **CSRF stays on (A05).** Forms via `form_with` / `button_to`; every state change is POST/PATCH/DELETE, never GET; never `skip_forgery_protection`.
6. **Uploads: allowlist + gate (A01/A04).** Validate content-type and size against allowlists; serve sensitive files through an authenticated action with `send_data` + `X-Content-Type-Options: nosniff`; never build a file path from user input.
7. **Secrets out of code and logs (A02).** `credentials.yml.enc` / ENV only; `config.filter_parameters` for passwords/tokens; never log secrets or PII.
8. **No unsafe deserialization (A08).** No `Marshal.load` / `YAML.load` on untrusted input — use `JSON.parse` or `YAML.safe_load`.
9. **Keep dependencies clean (A06).** `bin/bundler-audit` and `bin/importmap audit` green; `bin/brakeman --no-pager` reports zero warnings before merge.
10. **Authenticate correctly (A07).** Devise for `User` and (separately) `Admin`; the two never mix; admin/privileged actions sit behind `authenticate_admin!`. Generic auth-failure messages (don't reveal whether an account exists).
11. **Bulk/mass operations respect scope (A01).** `update_all` / `insert_all` / `destroy_all` only ever run on an already-scoped relation, never a bare model.
12. **Validate external URLs before fetching (A10 SSRF).** If code ever fetches a user-supplied URL, allowlist the host and block localhost / private ranges.

---

## OWASP Top 10 → where it lives in this repo

| OWASP (2021) | Guard in klaxon |
|---|---|
| A01 Broken Access Control | scoped finds (`ai/patterns/controllers.md`), `require_workshop_access!`, `authenticate_admin!` |
| A02 Cryptographic Failures | `credentials.yml.enc`, ENV (VAPID/geocoder keys), `filter_parameters` |
| A03 Injection | `sanitize_sql_array` in `Workshop#sorted_by_distance`; named binds in `Workshop.text_search`; ERB escaping |
| A04 Insecure Design | ActiveStorage type/size allowlists; append-only audit (`ai/patterns/data_integrity.md`) |
| A05 Security Misconfiguration | default Rails CSRF; `allow_browser versions: :modern` |
| A06 Vulnerable Components | `bundler-audit`, `importmap audit`, `brakeman` in CI |
| A07 Auth Failures | Devise (`User` + `Admin`), rate-limited/lockable where configured |
| A08 Integrity Failures | no `Marshal`/`YAML.load`; signed/encrypted cookies (Rails default) |
| A09 Logging Failures | log authz failures; never log secrets |
| A10 SSRF | allowlist any outbound user-supplied URL |

---

## Do / Don't

### Scope lookups (A01)

```ruby
# DO
@service_request = ServiceRequest.find_by!(id: params[:id], car: current_user.cars)
@service_request = @workshop.service_requests.find(params[:id])   # @workshop already verified

# DON'T
@service_request = ServiceRequest.find(params[:id])               # any driver can read any request
```

### Parameterize SQL (A03)

```ruby
# DO — named bind + sanitize_sql_like (Workshop.text_search)
where("name ILIKE :q OR address ILIKE :q", q: "%#{sanitize_sql_like(q)}%")

# DO — sanitize_sql_array wrapped in Arel.sql for a computed column (Workshop#sorted_by_distance)
select("workshops.*", Arel.sql(sanitize_sql_array(["... acos(... radians(?) ...) ...", lat, lng, lat])))

# DON'T
where("name ILIKE '%#{params[:q]}%'")     # SQL injection
order(params[:sort])                       # injectable ORDER BY
```

### Strong params + privilege attributes (A01)

```ruby
# DO — allowlist; set role from a validated set, not the raw param
params.require(:service_request).permit(:car_id, :description, :preferred_time)
new_role = params.dig(:workshop_operator, :role).to_s
return head :bad_request unless WorkshopOperator.roles.key?(new_role)

# DON'T
params.require(:workshop_operator).permit(:role)   # mass-assign of a privilege attr
User.create(params[:user])                          # no permit at all
params.permit!                                      # permits everything
```

### Serve a sensitive file (A01/A04)

```ruby
# DO — Admin::WorkshopsController#document: authed action, streamed, nosniff, content-type validated on upload
response.headers["X-Content-Type-Options"] = "nosniff"
send_data doc.download, filename: doc.filename.to_s, type: doc.content_type, disposition: "inline"

# DON'T
send_file "storage/#{params[:path]}"                # path traversal + no auth
link_to rails_blob_path(sensitive_doc)              # public signed URL for a private document
```

### Never render user input raw (A03)

```erb
<%# DO — escaped by default %>
<%= @review.body %>
<%= simple_format(@service_request.description) %>   <%# simple_format escapes content %>

<%# DON'T %>
<%= raw @review.body %>
<%= @review.body.html_safe %>
```

---

## Anti-Patterns

- **Unscoped `Model.find(params[:id])` on user data.** The most common broken-access-control bug — always scope.
- **String-interpolated SQL** in `where` / `order` / `find_by_sql` / `pluck`.
- **`raw` / `html_safe` on user-supplied content.** Stored XSS.
- **`permit!` or permitting privilege attributes** (`role`, `status`, `admin`) straight from the form.
- **Public ActiveStorage URLs for sensitive documents.** Signed ≠ authorized; gate through an admin/owner action.
- **`Marshal.load` / `YAML.load` on untrusted input.** Remote code execution.
- **Secrets committed or logged.** Keys in code, tokens in logs, PII in logs.
- **Disabling CSRF** or doing state changes over GET.
