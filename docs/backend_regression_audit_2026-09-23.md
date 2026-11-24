# Backend and Mobile Regression Audit

Date: 2026-09-23

Scope: Micro Mentor mobile app and supplied Postman collections. Agora RTC is
explicitly excluded.

## Regression Result

```text
flutter analyze: PASS (0 issues)
flutter test:    PASS (40 tests)
```

Covered automated areas include request encoding, token refresh/retry,
authentication parsing, mentor registration, public catalog requests,
onboarding draft save/ETag behavior, onboarding resume, previous-step edits,
home mapping, and app routing smoke tests.

This is not a live backend end-to-end pass. The hosted ALB did not answer HTTP
requests and refused HTTPS during this audit, so authenticated production flows
could not be exercised against it.

## Mobile Fixes Made During Audit

### Login role fallback

The Postman login example contains `id`, `email`, and tokens but no `role`.
Previously this made every such login default to `mentee`, including mentor
accounts. The mobile app now calls `GET /api/profile/` after login only when the
login response omits `role`, then routes using the authoritative profile role.

The preferred backend fix is still to include the complete routing information
in every login response.

### Mentor availability isolation

The mentor schedule previously called the public availability collection with
no `mentor_id`. The app now resolves the authenticated mentor profile ID from
the mentor dashboard and uses:

```http
GET /api/availability-windows/?mentor_id=<authenticated_mentor_profile_id>
```

It also includes that mentor ID when creating a window. The backend must ignore
or reject any foreign mentor ID on writes and enforce ownership from the access
token.

## Critical Backend Work

### 1. Restore the hosted API and add HTTPS

Observed on 2026-09-23:

```text
HTTP :80  -> timed out without response
HTTPS :443 -> connection refused
```

Host tested:

```text
micro-mentor-alb-869670005.us-east-1.elb.amazonaws.com
```

Required backend/infrastructure actions:

- Verify ALB target health, listener rules, security groups, application port,
  health-check path, and running service/task instances.
- Add an HTTPS listener with a valid certificate and redirect HTTP to HTTPS.
- Publish one stable API base URL. Do not require an insecure ATS exception on
  iOS for production.
- Add a cheap unauthenticated health endpoint such as `GET /api/health/`.

The app currently defaults to the local development URL
`http://172.20.10.13:8000/api`. Builds can target another environment with:

```text
--dart-define=API_BASE_URL=https://api.example.com/api
```

Do not switch the production build until the hosted HTTPS endpoint is healthy.

### 2. Return role and onboarding routing data from login

Required preferred login response:

```json
{
  "id": 12,
  "email": "mentor@example.com",
  "first_name": "Alex",
  "last_name": "Mentor",
  "role": "mentor",
  "access_token": "...",
  "refresh_token": "...",
  "mentor_profile_id": 17,
  "onboarding": {
    "application_id": 18,
    "status": "draft",
    "current_step": "services",
    "completion_percent": 60,
    "version": 4
  }
}
```

`role` must never be inferred from an email or token shape. The onboarding
summary can be omitted if `GET /api/mentor-onboarding/status/` is guaranteed,
but returning it avoids an extra routing request.

### 3. Restore the onboarding endpoints in Postman/OpenAPI

The supplied `micro_mentor_backend_postman_collection_FIXED` collection has no
mentor-onboarding requests. Add all of these with request and response examples:

```text
GET    /api/mentor-onboarding/
PATCH  /api/mentor-onboarding/
POST   /api/mentor-onboarding/submit/
GET    /api/mentor-onboarding/status/
POST   /api/mentor-onboarding/documents/upload-request/
POST   /api/mentor-onboarding/documents/<id>/confirm/
DELETE /api/mentor-onboarding/documents/<id>/
```

PATCH must return the full normalized draft and a new ETag. Details are in
`docs/backend_mentor_onboarding_resume_prompt.md`.

### 4. Implement real payment initiation

The app currently sends a generated value such as
`test_payment_<session_id>` to the confirmation endpoint. That is suitable only
for a backend sandbox stub and is not payment processing.

Add a flow such as:

```text
POST /api/sessions/<id>/payment/intent/
GET  /api/payments/<session_id>/
POST /api/sessions/<id>/payment/confirm/
```

The intent response should provide the payment provider, publishable client
configuration/client secret, amount, currency, and payment ID. Confirmation
must verify the payment server-to-server and be idempotent. The client must
never be able to confirm payment by inventing a provider transaction ID.

### 5. Define concrete bookable slots

`GET /api/mentors/<id>/availability/` currently maps recurring windows and
booked starts. The UI needs concrete slots for a date range, including interval,
package duration, timezone, existing bookings, buffers, and past times.

Recommended request:

```http
GET /api/mentors/<id>/availability/?from=2026-09-24&to=2026-10-24&duration_minutes=30&timezone=Asia/Karachi
```

Recommended response:

```json
{
  "mentor_id": 17,
  "timezone": "Asia/Karachi",
  "slots": [
    {
      "starts_at": "2026-09-24T09:00:00+05:00",
      "ends_at": "2026-09-24T09:30:00+05:00",
      "available": true
    }
  ]
}
```

Booking creation must lock/recheck the slot transactionally and return `409`
with code `slot_unavailable` if another booking wins the race.

## Contract Mismatches To Resolve

### Conversations

The app sends the newer domain payloads:

```json
{"type":"inquiry","mentor_id":17}
```

or:

```json
{"type":"session","session_id":44}
```

The Fixed Postman collection instead documents:

```text
participant_ids=<other_user_id>
related_session_id=<session_id>
```

Choose one canonical contract and update both implementation and collection.
The domain payload is recommended because the backend can derive participants,
enforce roles, and prevent arbitrary conversation membership. Creation should
be idempotent and return an existing open inquiry/session conversation where
appropriate.

### Booking list

The mobile app uses:

```http
GET /api/bookings/
```

The supplied collection documents only `POST /api/bookings/`. Add the GET
request and response example. Support filters such as `status`, `from`, `to`,
and server pagination.

### Mentor discovery pagination

The current collection documents only `q` and `category`. Add normal server
pagination (`page`/`page_size` or cursor) and return `count`, `next`,
`previous`, and `results`. Without it, the app cannot reliably load beyond the
first response page.

### Authentication body format

The collection uses multipart form-data while current auth calls use JSON. The
backend should explicitly support JSON for register, login, and token refresh,
then update Postman/OpenAPI to match. Keep one documented encoding per endpoint.

## Incomplete Backend-Dependent Features

### Session lifecycle

Add authenticated, ownership-checked APIs for:

```text
POST /api/sessions/<id>/cancel/
POST /api/sessions/<id>/reschedule/
POST /api/sessions/<id>/accept-reschedule/
POST /api/sessions/<id>/decline-reschedule/
```

Define allowed status transitions, cancellation windows, refunds, no-show
handling, and audit events. `complete/` must be idempotent and restricted to an
eligible participant/time window.

### Dashboard metrics

The app currently has to show zero for average rating and repeat-client rate.
Extend `GET /api/mentor-dashboard/` with at least:

```text
total_sessions
completed_sessions
upcoming_sessions_count
earnings_usd
currency
average_rating
review_count
repeat_client_percent
```

Do not calculate earnings from the length of `upcoming_sessions`.

### Availability management

- Return the mentor timezone from profile/dashboard and store IANA timezone IDs.
- Validate `starts_at < ends_at`, supported intervals, and overlapping windows.
- Scope write permissions to the authenticated mentor profile.
- Return `409` for windows that conflict with existing rules/bookings.
- Clarify whether DELETE is hard deletion or deactivation.

### Messaging

Text messaging is wired. Still needed for a complete product:

- Stable unread counts and a mark-read endpoint.
- Pagination for conversations and messages.
- Message ordering/cursors and duplicate-send idempotency.
- Attachment upload endpoints if attachment UI is enabled later.
- Realtime transport/push delivery if required; polling alone is not present.

### Notifications

No notification API is documented. Add device-token registration, notification
list, unread count, mark-read/mark-all-read, and booking/onboarding/payment
event generation before enabling the disabled notification control.

### Profile and media

Mentor professional profile edit, packages, reviews, and availability CRUD are
wired. Avatar/media upload and basic account edits are not documented. Use
private upload requests where necessary and return canonical media URLs only
after validation.

## Backend Regression Checklist

Run these in CI against a disposable database:

1. Register and login as mentee and mentor; assert role-correct routing fields.
2. Save two onboarding screens, log out/in, and assert exact resume state.
3. Verify public catalog GETs work without authorization.
4. Verify every write rejects missing auth and foreign-object ownership.
5. Create/update/delete mentor profile, package, and availability records.
6. Race two booking requests for one slot; exactly one may succeed.
7. Exercise payment intent, webhook/verification, idempotent confirmation, and
   failed/refunded states.
8. List sessions for both participants and test cancel/reschedule transitions.
9. Create inquiry and session conversations, send/list/read messages, and
   verify participant isolation.
10. Complete a session, create/edit/delete one review, and prevent duplicates.
11. Confirm pagination and filters on mentors, sessions, reviews, conversations,
    and messages.
12. Verify all 401/403/409/422 errors use the documented machine-readable
    envelope.

Agora channel/token issuance, media permissions, joining, reconnection, and RTC
quality behavior were intentionally not evaluated in this audit.
