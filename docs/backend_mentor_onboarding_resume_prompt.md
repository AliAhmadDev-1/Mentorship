# Backend Implementation Prompt: Resumable Mentor Onboarding

You are the backend developer for the Micro Mentor app. Implement durable,
screen-by-screen mentor onboarding so a mentor can close the mobile app at any
time, sign in later, resume at the correct screen, and edit previously saved
answers without losing later sections.

This is server-persisted draft state. Do not use an in-memory session, device
identifier, cookie, or temporary cache as the source of truth. The bearer token
identifies the user; the database stores the onboarding application and its
progress.

## Required User Experience

1. `POST /api/auth/register/` with `role: "mentor"` creates the account and one
   onboarding application in the same database transaction.
2. The new application starts with `status: "draft"` and
   `current_step: "professional_profile"`.
3. Each screen is saved independently with
   `PATCH /api/mentor-onboarding/`.
4. A successful PATCH is committed before a response is returned.
5. If a mentor completes two screens and closes the app, the next authenticated
   GET must return all saved data and `current_step: "verification"`.
6. After sign-in, the app calls `GET /api/mentor-onboarding/status/`. A mentor
   with an editable, incomplete application is routed to the returned
   `current_step`.
7. A mentor may navigate backward and update an earlier section. That PATCH
   updates only the supplied section and must not erase later saved sections.
8. Saving an earlier section must not regress progress unless the client
   explicitly sends an earlier `current_step`. The current mobile client will
   preserve the furthest reached step.

## Database Requirements

Store one onboarding application per mentor user with at least:

```text
id
user_id (unique foreign key)
status
current_step
completion_percent
version
profession
headline
company
years_experience
bio
linkedin_url
portfolio_url
timezone
accepts_inquiries
submitted_at
reviewed_at
review_notes
fields_requiring_changes
created_at
updated_at
```

Store categories and expertise as relations. Store draft packages and draft
availability as application-owned child rows. Documents remain private,
application-owned records.

Use these step values and this order only:

```text
professional_profile
expertise
verification
services
availability
review
```

Use these statuses:

```text
draft
pending_review
changes_requested
verified
rejected
```

`draft` and `changes_requested` are editable. `pending_review`, `verified`, and
`rejected` are read-only unless an explicit reviewer workflow changes status.

## Registration And Sign-In Responses

Mentor registration must not fail merely because optional onboarding sections
are empty. Registration creates the empty draft and returns:

```json
{
  "id": 42,
  "email": "mentor@example.com",
  "role": "mentor",
  "access_token": "...",
  "refresh_token": "...",
  "mentor_profile_id": 24,
  "onboarding": {
    "application_id": 18,
    "status": "draft",
    "current_step": "professional_profile",
    "completion_percent": 0,
    "version": 1
  }
}
```

The login response may include the same `onboarding` summary as an optimization,
but `GET /api/mentor-onboarding/status/` remains the authoritative routing API.
Do not create another application on each login or GET.

## Load And Status APIs

### Full draft

```http
GET /api/mentor-onboarding/
Authorization: Bearer <access_token>
```

Return the complete normalized draft, including all previously saved sections,
plus these routing fields:

```json
{
  "id": 18,
  "status": "draft",
  "current_step": "verification",
  "completion_percent": 35,
  "version": 3,
  "can_edit": true,
  "can_submit": false,
  "professional_profile": {},
  "category_ids": [],
  "expertise_ids": [],
  "documents": [],
  "packages": [],
  "timezone": null,
  "availability_windows": [],
  "accepts_inquiries": true,
  "review_notes": null,
  "fields_requiring_changes": []
}
```

Return an ETag response header, for example:

```http
ETag: "application-18-version-3"
```

### Lightweight routing status

```http
GET /api/mentor-onboarding/status/
Authorization: Bearer <access_token>
```

Return at least:

```json
{
  "application_id": 18,
  "status": "draft",
  "current_step": "verification",
  "completion_percent": 35,
  "version": 3,
  "can_edit": true,
  "can_submit": false,
  "fields_requiring_changes": []
}
```

The endpoint must be fast and side-effect free. If an older mentor account has
no application, create one once in a transaction or return a documented 404
that can be repaired. Never return a fake empty draft while silently discarding
saved data.

## Draft Save Contract

All five screen saves use exactly:

```http
PATCH /api/mentor-onboarding/
Authorization: Bearer <access_token>
Content-Type: application/json
If-Match: "application-18-version-3"
```

Do not use `/api/mentor-onboarding/update/`.

PATCH is partial:

- Omitted scalar fields and omitted sections remain unchanged.
- `professional_profile` updates only fields supplied inside that object.
- When `category_ids`, `expertise_ids`, `packages`, or
  `availability_windows` are supplied, treat each supplied list as the complete
  replacement for that list. Omitted lists remain unchanged.
- Validate ownership for every related ID and child record.
- Accept client-generated `client_id` values for idempotent package and
  availability upserts.
- Increment `version` exactly once per successful PATCH.
- Recalculate `completion_percent` on the server.
- Return the full updated draft and the new ETag.
- Perform each PATCH atomically.

If `If-Match` is stale, make no changes and return:

```http
409 Conflict
```

```json
{
  "error": {
    "code": "stale_application_version",
    "message": "This onboarding application was updated elsewhere. Reload and try again."
  }
}
```

Never allow the generic PATCH endpoint to set `status`, reviewer fields,
`submitted_at`, `reviewed_at`, or another user's application.

## Screen Payloads

### Screen 1: professional profile

```json
{
  "current_step": "expertise",
  "professional_profile": {
    "profession": "software_engineering",
    "headline": "Senior Flutter Engineer at Acme",
    "company": "Acme",
    "years_experience": 8,
    "bio": "I help mobile engineers build reliable Flutter applications.",
    "linkedin_url": "https://linkedin.com/in/example",
    "portfolio_url": "https://example.com"
  }
}
```

### Screen 2: expertise

```json
{
  "current_step": "verification",
  "category_ids": [1, 3],
  "expertise_ids": [2, 5, 9]
}
```

### Screen 3: verification progress

Document uploads use their dedicated endpoints. Advancing the draft uses:

```json
{
  "current_step": "services"
}
```

### Screen 4: services

```json
{
  "current_step": "availability",
  "accepts_inquiries": true,
  "packages": [
    {
      "client_id": "mobile-30",
      "duration_minutes": 30,
      "price_usd": "35.00",
      "is_popular": true,
      "is_active": true
    }
  ]
}
```

### Screen 5: availability

```json
{
  "current_step": "review",
  "timezone": "Asia/Karachi",
  "availability_windows": [
    {
      "client_id": "day-1-090000",
      "weekday": 1,
      "starts_at": "09:00:00",
      "ends_at": "17:00:00",
      "slot_interval_minutes": 30,
      "is_active": true
    }
  ]
}
```

## Previous-Screen Editing

Editing previous information is required behavior, not a new application:

- A mentor at `current_step: "availability"` may PATCH
  `professional_profile` and keep `current_step: "availability"`.
- Existing categories, expertise, documents, packages, and availability must
  remain untouched when omitted.
- Revalidate the entire draft after an edit. If an earlier change makes a later
  section invalid, return the normalized draft with updated
  `completion_percent`/`can_submit` and precise validation information. Do not
  delete unrelated data.
- For `changes_requested`, allow edits to any section and return reviewer notes
  and `fields_requiring_changes` on every GET/PATCH response.

## Submit And Routing Rules

Submit with:

```http
POST /api/mentor-onboarding/submit/
Authorization: Bearer <access_token>
Content-Type: application/json
```

```json
{
  "confirm_information_accurate": true,
  "terms_version": "mentor-terms-2026-08"
}
```

Validate the complete stored draft, not only the request body. On success set
`status: "pending_review"`, record submission metadata, and make the draft
read-only. Repeated submit requests must not create duplicate applications.

Mobile routing is based on backend state:

```text
draft / changes_requested -> onboarding at current_step
pending_review             -> onboarding status view
verified                   -> mentor dashboard
rejected                   -> onboarding decision/status view
mentee                     -> mentee home
```

## Security And Error Requirements

- Require a valid bearer token for every onboarding endpoint.
- Return `401` only for missing/invalid/expired authentication.
- Return `403` for an authenticated non-mentor or ownership violation.
- Never accept `user_id` or `application_id` from the mobile body to choose the
  target application.
- Return validation errors in a stable field map, for example:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Some onboarding fields need attention.",
    "fields": {
      "professional_profile.headline": ["This field is required."],
      "packages": ["Add at least one active package."]
    }
  }
}
```

## Required Acceptance Tests

1. Register a mentor and assert one draft is created.
2. Save screen 1, then screen 2; simulate logout/login; assert status and full
   GET both return `current_step: "verification"` and both sections' data.
3. Update screen 1 while the saved step is `availability`; assert later
   expertise, packages, and availability remain unchanged and the saved step
   remains `availability` when that value is sent.
4. Send two PATCH requests with the same ETag; assert one succeeds and the
   stale request returns 409 without overwriting data.
5. Retry an identical package/availability request; assert `client_id` prevents
   duplicate child rows.
6. Assert a mentor cannot read or mutate another mentor's draft.
7. Assert `pending_review`, `verified`, and `rejected` drafts reject normal
   PATCH requests.
8. Assert submit validates the stored aggregate and cannot create duplicate
   applications or submissions.
9. Assert status GET has no side effects and stays consistent with full GET.
10. Assert all successful PATCH responses contain the full normalized draft,
    incremented `version`, and matching ETag.

Deliver migrations, serializers/schemas, permissions, endpoint handlers,
transactional services, API tests, and OpenAPI/Postman updates together.
