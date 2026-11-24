# Mentor Onboarding API Contract

> Updated 2026-09-06: mentor registration is account-only JSON. Professional
> fields belong to the onboarding draft endpoints. Any conflicting legacy text
> in this document is superseded by this note and the registration section.

## Document Purpose

This document is the implementation handoff for the backend engineer building
mentor onboarding. It describes the product behavior, ownership model, database
entities, API contract, validation, document handling, review workflow, and
acceptance criteria expected by the Flutter application.

The connected Flutter flow is available at:

```text
lib/features/mentor_onboarding/presentation/mentor_onboarding_screen.dart
```

The screen loads and saves drafts, uploads documents directly to signed storage
URLs, and submits applications through the endpoints in this contract.

## Product Summary

A mentor is not simply a normal user with a different role. A mentor must:

1. Create an account.
2. Complete a resumable professional application.
3. Select categories and expertise from backend reference data.
4. Provide private evidence supporting identity and professional experience.
5. Configure mentoring packages and initial availability.
6. Confirm the accuracy of the application and submit it.
7. Wait for an authorized reviewer to approve it or request changes.
8. Become discoverable and bookable only after approval.

The application must support leaving and returning at any step. Every completed
screen should be saved independently. A temporary network failure must not force
the mentor to restart the complete process.

## Goal

Create a resumable mentor application, verify professional evidence privately,
and publish only approved mentors. A mentor account may use the app while its
application is in draft or review, but it must not appear in mentor discovery or
accept paid bookings until verified.

## Scope

### Included

- Mentor account creation without requiring a completed professional profile.
- A single active onboarding application per mentor user.
- Partial draft saves for every onboarding screen.
- Category and expertise selection.
- Private proof-document uploads.
- Draft package and availability configuration.
- Submission validation and status transitions.
- Staff review, approval, rejection, and change requests.
- Audit events and mentor notifications.
- Activation of the public mentor profile after approval.

### Not Included in the First Backend Release

- Automated credential verification against LinkedIn or employers.
- Payment-provider onboarding or tax verification.
- Background checks.
- Multiple concurrent mentor applications for one user.
- Public access to verification documents.
- Real-time reviewer chat. Review notes and notifications are sufficient.

## Frontend Screen Mapping

The current mobile flow contains six screens and one result state:

| Step | Screen | Data | Backend action |
| --- | --- | --- | --- |
| 1 | Professional profile | Profession, headline, company, experience, bio | `PATCH /api/mentor-onboarding/` |
| 2 | Expertise | Category IDs, expertise IDs, LinkedIn, portfolio | Load reference data, then `PATCH /api/mentor-onboarding/` |
| 3 | Verification | Identity, employment, and certificate files | Request upload, upload privately, confirm document |
| 4 | Services | Session durations, prices, popular package, inquiries | `PATCH /api/mentor-onboarding/` |
| 5 | Availability | Timezone, weekdays, start/end time, interval | `PATCH /api/mentor-onboarding/` |
| 6 | Review | Complete draft and accuracy agreement | `GET /api/mentor-onboarding/`, then `POST /api/mentor-onboarding/submit/` |
| Result | Pending review | Current review status and next action | `GET /api/mentor-onboarding/status/` |

The backend response is authoritative. The mobile client may optimistically
show entered values, but after every successful save it should replace local
draft data with the response returned by the backend.

## End-to-End Request Sequence

The expected first-time onboarding sequence is:

```text
Mobile                  API                         Storage / reviewer
  |                      |                                  |
  | POST auth/register   |                                  |
  |--------------------->| create user + draft              |
  |<---------------------| tokens + draft status            |
  |                      |                                  |
  | GET categories       |                                  |
  | GET expertise        |                                  |
  | GET onboarding draft |                                  |
  |--------------------->|                                  |
  |<---------------------| resumable draft                  |
  |                      |                                  |
  | PATCH each step      |                                  |
  |--------------------->| validate + save                  |
  |<---------------------| normalized complete draft        |
  |                      |                                  |
  | request upload URL   |                                  |
  |--------------------->| create document record           |
  |<---------------------| short-lived signed URL           |
  | PUT file ---------------------------------------------->|
  | confirm document     |                                  |
  |--------------------->| verify object + scan             |
  |<---------------------| document status                  |
  |                      |                                  |
  | POST submit          |                                  |
  |--------------------->| final validation + lock draft    |
  |<---------------------| pending_review                   |
  |                      |------------ reviewer queue ----->|
  |                      |<----------- review decision -----|
  | GET status           |                                  |
  |--------------------->|                                  |
  |<---------------------| verified / changes_requested     |
```

## Recommended Data Model

The names below are recommendations and can be adapted to the existing Django
model conventions. The relationships and constraints are more important than
the exact class names.

### `MentorApplication`

One-to-one with a user whose role is `mentor`.

| Field | Type | Rules |
| --- | --- | --- |
| `id` | bigint/UUID | Primary key |
| `user_id` | foreign key | Unique; role must be mentor |
| `status` | enum | Draft lifecycle defined below |
| `current_step` | enum/string | Last screen successfully saved |
| `completion_percent` | integer | Backend-calculated, 0 through 100 |
| `profession` | string | Controlled backend value |
| `headline` | string | Maximum 120 characters |
| `company` | string | Maximum 120 characters; optional |
| `years_experience` | integer | 0 through 60 |
| `bio` | text | Recommended 80 through 2,000 characters |
| `linkedin_url` | URL | Optional HTTPS URL |
| `portfolio_url` | URL | Optional HTTPS URL |
| `timezone` | IANA timezone | Example: `Asia/Karachi` |
| `accepts_inquiries` | boolean | Defaults to `true` |
| `terms_version` | string | Version accepted at submission |
| `terms_accepted_at` | timestamp | Set only during valid submission |
| `submitted_at` | timestamp | Nullable |
| `reviewed_at` | timestamp | Nullable |
| `reviewer_id` | staff foreign key | Nullable |
| `review_notes` | text | Nullable; mentor-visible when appropriate |
| `fields_requiring_changes` | JSON array | Stable field paths |
| `version` | integer | Increment on every draft mutation |
| `created_at` | timestamp | Server generated |
| `updated_at` | timestamp | Server generated |

Use many-to-many relationships from the application to existing `Category` and
`Expertise` records. Do not store category or expertise display names directly
in the application.

### `MentorApplicationPackage`

Draft package configuration owned by the application.

| Field | Type | Rules |
| --- | --- | --- |
| `id` | bigint/UUID | Primary key |
| `application_id` | foreign key | Cascade with application |
| `client_id` | string | Unique per application; supports idempotent mobile saves |
| `duration_minutes` | integer | Allowed values initially: 15, 30, 45, 60 |
| `price_usd` | decimal(10,2) | Greater than zero; apply product min/max |
| `is_popular` | boolean | At most one active package may be popular |
| `is_active` | boolean | Defaults to true |

These records are drafts and must not appear in public package endpoints before
application approval.

### `MentorApplicationAvailability`

| Field | Type | Rules |
| --- | --- | --- |
| `id` | bigint/UUID | Primary key |
| `application_id` | foreign key | Cascade with application |
| `client_id` | string | Unique per application |
| `weekday` | integer | ISO weekday 1 Monday through 7 Sunday |
| `starts_at` | time | Local time in application timezone |
| `ends_at` | time | Must be after start time |
| `slot_interval_minutes` | integer | Allowed values: 15, 30, 45, 60 |
| `is_active` | boolean | Defaults to true |

Reject overlapping active windows on the same weekday. Store the IANA timezone
on the application and keep window times local so daylight-saving conversion is
performed when concrete bookable slots are generated.

### `MentorVerificationDocument`

| Field | Type | Rules |
| --- | --- | --- |
| `id` | bigint/UUID | Primary key |
| `application_id` | foreign key | Owner application |
| `document_type` | enum | Identity, employment, certificate, education, portfolio, other |
| `original_file_name` | string | Sanitized for display only |
| `storage_key` | string | Private object key; never expose directly |
| `content_type` | string | PDF, JPEG, or PNG only |
| `size_bytes` | integer | Maximum 10 MB |
| `checksum_sha256` | string | Required after upload confirmation |
| `status` | enum | Requested, uploaded, scanning, ready, unsafe, rejected, deleted |
| `rejection_reason` | string | Nullable |
| `uploaded_at` | timestamp | Nullable |
| `created_at` | timestamp | Server generated |

### `MentorApplicationReviewEvent`

Append-only audit history. Never update or delete review events through normal
application code.

| Field | Type | Description |
| --- | --- | --- |
| `application_id` | foreign key | Reviewed application |
| `actor_id` | user/staff foreign key | Person or service causing the event |
| `event_type` | enum | Submitted, viewed, document_downloaded, approved, changes_requested, rejected, reopened |
| `metadata` | JSON | Changed fields, reason codes, request ID |
| `created_at` | timestamp | Immutable timestamp |

## Permissions Matrix

| Action | Mentee | Mentor owner | Other mentor | Reviewer/staff |
| --- | --- | --- | --- | --- |
| Create mentor draft | No | Automatic at registration | No | Optional admin action |
| Read draft | No | Yes | No | Yes |
| Edit draft | No | Draft/changes requested only | No | No direct edit |
| Upload/delete proof | No | Editable states only | No | Read through audited URL |
| Submit/resubmit | No | Yes when valid | No | No |
| View review queue | No | No | No | Yes |
| Approve/request changes/reject | No | No | No | Yes |
| Read public mentor profile | Yes | Yes | Yes | Yes |

Object-level permission checks are mandatory. Knowing an application or
document ID must never allow another user to access it.

API root used by the mobile app:

```text
/api
```

All write endpoints and private onboarding endpoints require:

```http
Authorization: Bearer <access_token>
Accept: application/json
```

The existing `GET` endpoints for categories, expertise, packages, availability
windows, and mentor profiles are public and must not require an authorization
header.

### API Inventory

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/api/auth/register/` | Create mentor account, profile, and initial verification draft |
| `GET` | `/api/mentor-onboarding/` | Load the complete resumable draft |
| `PATCH` | `/api/mentor-onboarding/` | Save one or more draft sections |
| `POST` | `/api/mentor-onboarding/documents/upload-request/` | Create document record and signed upload URL |
| `POST` | `/api/mentor-onboarding/documents/{id}/confirm/` | Verify an uploaded object and begin scanning |
| `DELETE` | `/api/mentor-onboarding/documents/{id}/` | Remove an editable draft document |
| `POST` | `/api/mentor-onboarding/submit/` | Validate and submit or resubmit the application |
| `GET` | `/api/mentor-onboarding/status/` | Return lightweight status and review guidance |
| `GET` | `/api/categories/` | Return selectable mentor categories |
| `GET` | `/api/expertise/` | Return selectable expertise values |
| `GET` | `/api/admin/mentor-applications/` | Reviewer queue |
| `GET` | `/api/admin/mentor-applications/{id}/` | Reviewer application detail |
| `POST` | `/api/admin/mentor-applications/{id}/approve/` | Verify and activate mentor |
| `POST` | `/api/admin/mentor-applications/{id}/request-changes/` | Return application for corrections |
| `POST` | `/api/admin/mentor-applications/{id}/reject/` | Reject application |
| `GET` | `/api/admin/mentor-applications/{id}/documents/{document_id}/download/` | Create audited signed download URL |

## Status Lifecycle

```text
draft -------------> pending_review -------------> verified
                          |   |
                          |   +-------------------> rejected
                          |
                          +-> changes_requested --> pending_review
```

Recommended status values:

- `draft`: mentor is still completing onboarding.
- `pending_review`: application is locked for reviewer assessment.
- `changes_requested`: mentor may edit the fields identified by the reviewer.
- `verified`: profile can be activated and shown in discovery.
- `rejected`: application cannot be resubmitted unless reopened by staff.

Allowed transitions:

| From | To | Actor | Condition |
| --- | --- | --- | --- |
| New mentor account | `draft` | System | Mentor registration committed |
| `draft` | `pending_review` | Mentor owner | Full validation succeeds |
| `pending_review` | `verified` | Reviewer | Evidence approved |
| `pending_review` | `changes_requested` | Reviewer | Notes and field paths supplied |
| `pending_review` | `rejected` | Reviewer | Reason code and notes supplied |
| `changes_requested` | `pending_review` | Mentor owner | Corrections pass validation |
| `rejected` | `draft` | Authorized staff | Explicit reopen action, if product permits |

Any transition not listed above must return `409 Conflict`. Status must never be
accepted as a freely writable field on the general draft `PATCH` endpoint.

## 1. Create Mentor Account

`POST /api/auth/register/`

Mentor registration atomically creates the user and initial onboarding draft.
The public mentor profile is created or activated only after approval.

```json
{
  "email": "mentor@example.com",
  "password": "StrongPassword123",
  "first_name": "Sarah",
  "last_name": "Chen",
  "role": "mentor"
}
```

Professional fields, categories, and expertise are saved after registration
through `PATCH /api/mentor-onboarding/`.

Response `201`:

```json
{
  "id": 42,
  "email": "mentor@example.com",
  "role": "mentor",
  "access_token": "...",
  "refresh_token": "...",
  "onboarding": {
    "application_id": 18,
    "status": "draft",
    "current_step": "professional_profile",
    "completion_percent": 0
  }
}
```

Mentee registration remains unchanged and does not create a mentor profile or
mentor verification draft.

## 2. Read Onboarding Draft

`GET /api/mentor-onboarding/`

Response `200`:

```json
{
  "id": 18,
  "status": "draft",
  "current_step": "expertise",
  "completion_percent": 32,
  "professional_profile": {
    "profession": "software_engineering",
    "headline": "Senior Flutter Engineer at Acme",
    "company": "Acme",
    "years_experience": 8,
    "bio": "I help mobile engineers build reliable Flutter products.",
    "linkedin_url": "https://linkedin.com/in/sarah-chen",
    "portfolio_url": "https://sarah.example.com"
  },
  "category_ids": [1],
  "expertise_ids": [2, 5],
  "documents": [],
  "packages": [],
  "availability_windows": [],
  "accepts_inquiries": true,
  "submitted_at": null,
  "reviewed_at": null,
  "review_notes": null
}
```

## 3. Save Draft

`PATCH /api/mentor-onboarding/`

Allow partial updates and save after each screen. Repeating the same payload
must be idempotent.

Professional profile payload:

```json
{
  "current_step": "expertise",
  "professional_profile": {
    "profession": "software_engineering",
    "headline": "Senior Flutter Engineer at Acme",
    "company": "Acme",
    "years_experience": 8,
    "bio": "I help mobile engineers build reliable Flutter products.",
    "linkedin_url": "https://linkedin.com/in/sarah-chen",
    "portfolio_url": "https://sarah.example.com"
  }
}
```

Expertise payload:

```json
{
  "current_step": "verification",
  "category_ids": [1, 3],
  "expertise_ids": [2, 5, 9]
}
```

Services payload:

```json
{
  "current_step": "availability",
  "accepts_inquiries": true,
  "packages": [
    {
      "client_id": "mobile-15",
      "duration_minutes": 15,
      "price_usd": "20.00",
      "is_popular": false,
      "is_active": true
    },
    {
      "client_id": "mobile-30",
      "duration_minutes": 30,
      "price_usd": "35.00",
      "is_popular": true,
      "is_active": true
    },
    {
      "client_id": "mobile-45",
      "duration_minutes": 45,
      "price_usd": "50.00",
      "is_popular": false,
      "is_active": true
    }
  ]
}
```

Availability payload:

```json
{
  "current_step": "review",
  "timezone": "Asia/Karachi",
  "availability_windows": [
    {
      "client_id": "mon-0900",
      "weekday": 1,
      "starts_at": "09:00:00",
      "ends_at": "17:00:00",
      "slot_interval_minutes": 30,
      "is_active": true
    },
    {
      "client_id": "wed-0900",
      "weekday": 3,
      "starts_at": "09:00:00",
      "ends_at": "17:00:00",
      "slot_interval_minutes": 30,
      "is_active": true
    }
  ]
}
```

Response `200` should return the complete updated draft shown in section 2.

### Draft Save Semantics

The `PATCH` endpoint must follow these rules:

- Omitted scalar fields remain unchanged.
- An explicitly supplied `null` clears an optional field and is rejected for a
  required/non-nullable field.
- `category_ids` and `expertise_ids` are complete replacements when supplied.
  An empty list intentionally clears the selection.
- `packages` and `availability_windows` are complete replacements when
  supplied. The backend should upsert by `client_id` and remove draft children
  omitted from that supplied list.
- IDs must belong to active reference records. Unknown or inactive IDs return a
  field error.
- The mentor can save incomplete values while status is `draft`. Final required
  field validation happens during submission.
- Format, range, ownership, and security validation always applies, including
  draft mode. For example, negative experience or an invalid URL must never be
  saved.
- The response returns the full normalized application, not only changed
  fields.
- Every successful mutation increments `version` and recalculates
  `completion_percent`.

### Concurrent Saves

Mobile requests can be retried or arrive out of order. Include the application
version in the request to prevent an older save from overwriting newer data.

Recommended request header:

```http
If-Match: "application-18-version-7"
```

Recommended response header:

```http
ETag: "application-18-version-8"
```

If the version does not match, return `409 Conflict`:

```json
{
  "code": "stale_application_version",
  "detail": "This application was updated by another request.",
  "current_version": 8
}
```

If ETags do not fit the existing backend conventions, accept a numeric
`version` in the JSON body. The behavior is more important than the transport.

### Completion Percentage

Calculate completion on the backend so Android, iOS, and future web clients all
show the same value. Suggested weighting:

| Section | Weight |
| --- | ---: |
| Professional profile | 25% |
| Categories and expertise | 15% |
| Required proof ready | 25% |
| At least one active package | 15% |
| At least one availability window and timezone | 15% |
| Terms confirmation | 5% |

Do not use completion percentage as submission validation. It is a display
value; the final validator remains authoritative.

## 4. Upload Verification Proof

Recommended secure flow:

### Request Upload

`POST /api/mentor-onboarding/documents/upload-request/`

```json
{
  "document_type": "employment",
  "file_name": "employment-letter.pdf",
  "content_type": "application/pdf",
  "size_bytes": 482103
}
```

Response `201`:

```json
{
  "document_id": 71,
  "upload_url": "https://private-storage.example/signed-upload",
  "upload_method": "PUT",
  "upload_headers": {
    "Content-Type": "application/pdf"
  },
  "expires_at": "2026-08-30T12:15:00Z"
}
```

The mobile app uploads directly to private object storage and then confirms it:

`POST /api/mentor-onboarding/documents/71/confirm/`

```json
{
  "checksum_sha256": "<hex digest>"
}
```

Response `200`:

```json
{
  "id": 71,
  "document_type": "employment",
  "file_name": "employment-letter.pdf",
  "status": "uploaded",
  "uploaded_at": "2026-08-30T12:04:10Z"
}
```

Delete before submission:

`DELETE /api/mentor-onboarding/documents/71/` -> `204`

Allowed document types:

- `identity`
- `employment`
- `certificate`
- `education`
- `portfolio`
- `other`

Security requirements:

- Keep the storage bucket private.
- Never return a permanent public URL.
- Reviewer downloads must use short-lived signed URLs.
- Encrypt files at rest and in transit.
- Malware-scan documents before marking them ready.
- Restrict formats to PDF, JPG, and PNG and enforce a 10 MB limit.
- Record reviewer access in an audit log.
- Define retention and deletion rules for rejected/closed applications.

### Upload Behavior

Creating an upload request should create a document row in `requested` status
and generate a random storage key. Never derive the storage key directly from
the user-supplied file name.

On confirmation, the backend must verify that:

- The object exists at the expected private storage key.
- Its byte length matches the declared maximum and, preferably, the request.
- Its detected MIME type is allowed; do not trust only the file extension.
- Its SHA-256 checksum matches the confirmation payload.
- The object belongs to the requesting mentor's application.
- The upload URL has not expired or already been confirmed.

After confirmation, set status to `scanning` and enqueue malware/content
scanning. Set it to `ready` only after the scan succeeds. An application cannot
be submitted while a required document is `requested`, `uploaded`, `scanning`,
`unsafe`, or `rejected`.

If direct-to-storage uploads are unavailable for the first release, an interim
endpoint may accept `multipart/form-data`:

```text
POST /api/mentor-onboarding/documents/
```

Multipart fields:

```text
document_type=employment
file=<binary PDF/JPG/PNG>
```

The same ownership, scanning, MIME detection, encryption, size, retention, and
audit requirements still apply. Direct signed uploads are preferred because
large files do not pass through the application server.

## 5. Submit Application

`POST /api/mentor-onboarding/submit/`

```json
{
  "confirm_information_accurate": true,
  "terms_version": "mentor-terms-2026-08"
}
```

Response `200`:

```json
{
  "application_id": 18,
  "status": "pending_review",
  "submitted_at": "2026-08-30T12:10:00Z",
  "estimated_review_days": 3
}
```

Submission validation should return `422` with field-addressable errors:

```json
{
  "detail": "Complete the required mentor information.",
  "errors": {
    "professional_profile.headline": ["This field is required."],
    "expertise_ids": ["Select at least one expertise."],
    "documents.employment": ["Add employment or equivalent proof."],
    "packages": ["Add at least one active package."],
    "availability_windows": ["Add at least one availability window."]
  }
}
```

### Submission Validation Matrix

Run the complete validation in one pass and return all discovered field errors
so the mentor can fix them together.

| Field/section | Submission requirement |
| --- | --- |
| Account | Authenticated user exists, is active, and role is mentor |
| Status | Must be `draft` or `changes_requested` |
| Profession | Must be a supported controlled value |
| Headline | Required; 10 to 120 characters |
| Company | Optional; maximum 120 characters |
| Experience | Required; integer from 0 to 60 |
| Bio | Required; recommended 80 to 2,000 characters |
| LinkedIn | Optional valid HTTPS URL |
| Portfolio | Optional valid HTTPS URL |
| Categories | At least one active category |
| Expertise | At least one active expertise item |
| Identity proof | At least one `ready` document if required by policy |
| Professional proof | At least one ready employment, certificate, education, or portfolio document |
| Packages | At least one active package with valid duration and price |
| Availability | At least one non-overlapping active window |
| Timezone | Valid IANA timezone identifier |
| Agreement | `confirm_information_accurate` must be true |
| Terms | Supplied version must equal the currently accepted mentor terms version |

Proof requirements should be represented by backend policy/configuration rather
than hard-coded in the mobile app. For example, a product decision may permit a
verified company email plus LinkedIn instead of an employment document.

### Submission Transaction

Submission must be atomic. Within one database transaction:

1. Lock the application row for update.
2. Confirm the current status permits submission.
3. Run full application and child-record validation.
4. Verify required documents are in `ready` status.
5. Store the accepted terms version and timestamp.
6. Set status to `pending_review`.
7. Set `submitted_at` to the server time.
8. Clear obsolete change-request fields and review notes where appropriate.
9. Append a `submitted` review event.
10. Commit the transaction.
11. Enqueue notifications only after the transaction commits.

Repeated submission of the same already-pending application should not create
duplicate review jobs. Return either the existing `pending_review` response with
`200`, or a consistent `409 application_already_submitted` response.

## 6. Application Status

`GET /api/mentor-onboarding/status/`

```json
{
  "application_id": 18,
  "status": "changes_requested",
  "submitted_at": "2026-08-30T12:10:00Z",
  "reviewed_at": "2026-09-01T09:30:00Z",
  "review_notes": "Please provide clearer employment proof.",
  "fields_requiring_changes": ["documents.employment"],
  "can_edit": true,
  "can_resubmit": true
}
```

### Editing Rules by Status

| Status | Mentor can edit | Mentor can upload/delete proof | Mentor can submit |
| --- | --- | --- | --- |
| `draft` | Yes | Yes | Yes when valid |
| `pending_review` | No | No | No |
| `changes_requested` | Yes | Yes | Yes when valid |
| `verified` | No through onboarding API | No | No |
| `rejected` | No | No | No |

For `changes_requested`, the first release may allow editing the full draft even
when the response names specific fields. The named fields are primarily for UX
guidance. If field-level write restrictions are added later, enforce them on the
backend and return clear permission errors.

When a mentor is verified, ordinary profile/package/availability management
should move to the existing production endpoints rather than continuing through
the onboarding draft API.

## 7. Reference Data

Reuse the existing endpoints:

```text
GET /api/categories/
GET /api/expertise/
```

The frontend needs stable numeric IDs, display names, slugs, active flags, and
optional ordering fields.

Recommended response shape:

```json
{
  "results": [
    {
      "id": 1,
      "name": "Mobile Development",
      "slug": "mobile-development",
      "is_active": true,
      "sort_order": 10
    }
  ]
}
```

Inactive values already selected in an old draft may be returned in the draft
for display, but submission should ask the mentor to replace them.

## 8. Admin Review APIs

These should require a staff/reviewer permission:

```text
GET  /api/admin/mentor-applications/?status=pending_review
GET  /api/admin/mentor-applications/{application_id}/
POST /api/admin/mentor-applications/{application_id}/approve/
POST /api/admin/mentor-applications/{application_id}/request-changes/
POST /api/admin/mentor-applications/{application_id}/reject/
GET  /api/admin/mentor-applications/{application_id}/documents/{document_id}/download/
```

### Review Queue

`GET /api/admin/mentor-applications/` should support:

```text
status=pending_review
q=name-or-email
profession=software_engineering
submitted_before=2026-09-01T00:00:00Z
submitted_after=2026-08-01T00:00:00Z
ordering=submitted_at
page=1
page_size=25
```

Return lightweight rows suitable for a review queue:

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 18,
      "mentor": {
        "id": 42,
        "name": "Sarah Chen",
        "email": "mentor@example.com"
      },
      "profession": "software_engineering",
      "headline": "Senior Flutter Engineer at Acme",
      "status": "pending_review",
      "submitted_at": "2026-08-30T12:10:00Z",
      "document_count": 2
    }
  ]
}
```

The application detail endpoint should return the complete application plus
review history and document metadata. It must not return raw storage keys or
permanent file URLs.

Approve payload:

```json
{
  "notes": "Experience and identity verified."
}
```

Request-changes payload:

```json
{
  "notes": "Please upload a readable employment letter.",
  "fields_requiring_changes": ["documents.employment"]
}
```

Reject payload:

```json
{
  "reason_code": "insufficient_professional_evidence",
  "notes": "The supplied evidence does not demonstrate the stated experience."
}
```

Review actions must require a fresh `pending_review` status. Use row locking or
an atomic conditional update so two reviewers cannot approve and reject the
same application concurrently. A second conflicting action should receive
`409 application_already_reviewed` and the current application status.

Approval must atomically:

1. Set onboarding status to `verified`.
2. Set the mentor profile to active and verified.
3. Enable discovery visibility and booking eligibility.
4. Record reviewer ID and timestamps in an immutable audit log.
5. Notify the mentor.

### Materializing Production Records

Choose one of these implementation strategies and keep it consistent:

1. **Recommended:** Store onboarding packages and availability in dedicated
   draft tables, then create production `MentorProfile`, `Package`, and
   `AvailabilityWindow` records during approval.
2. Store them in production tables from the beginning with `is_active=false`
   and activate them during approval.

Dedicated draft tables provide stronger isolation and prevent unfinished
records leaking through existing list endpoints. If production tables are used,
every public query must explicitly filter by both mentor verification and record
activation status.

Approval should use `update_or_create` or equivalent idempotent operations. If a
notification task retries, it must not duplicate packages or availability
windows.

## Standard API Behavior

### Response and Error Envelope

Use one predictable error format for every onboarding endpoint:

```json
{
  "code": "validation_error",
  "detail": "Some fields need attention.",
  "errors": {
    "professional_profile.bio": ["Use at least 80 characters."]
  },
  "request_id": "req_01J..."
}
```

Recommended status codes:

| Status | Meaning |
| ---: | --- |
| `200` | Read, patch, submit, or review action succeeded |
| `201` | Account/document upload request created |
| `204` | Document deleted |
| `400` | Malformed JSON or unsupported request shape |
| `401` | Missing, invalid, or expired access token |
| `403` | Authenticated user lacks role/object permission |
| `404` | Resource does not exist or is not visible to caller |
| `409` | Invalid state transition, stale version, or concurrent review |
| `413` | Upload exceeds size limit |
| `415` | Unsupported document content type |
| `422` | Well-formed request failed field/business validation |
| `429` | Rate limit exceeded |

Do not use `401` for an authenticated mentor who lacks permission; return `403`.
This distinction is important because the mobile app treats `401` as session
expiration and signs the user out.

### Serialization Rules

- JSON field names use `snake_case`.
- Timestamps use UTC ISO 8601 with a `Z` suffix.
- Timezone values use IANA identifiers, not numeric UTC offsets.
- Money is serialized as a two-decimal string or a consistently parsed decimal,
  never a binary float internally.
- Weekdays use ISO values 1 through 7.
- Empty collections are returned as `[]`, never `null`.
- Optional scalar values may be `null`; required scalar keys should always be
  present in complete responses.
- Server-generated IDs are stable and must not be reused after deletion.

### Idempotency and Rate Limits

Accept an `Idempotency-Key` header for account creation, upload requests,
submission, and reviewer decisions. Store the key with user, endpoint, request
hash, and response for a limited period.

Apply reasonable limits, for example:

- Draft saves: 60 per minute per mentor.
- Upload requests: 20 per hour per mentor.
- Submission attempts: 10 per hour per mentor.
- Reviewer document downloads: audited and rate-limited.

## Notifications

Send notifications after transaction commit for:

- Application submitted: confirmation to mentor and queue notification to staff.
- Changes requested: mentor receives reviewer notes and affected fields.
- Application approved: mentor receives verified status and dashboard access.
- Application rejected: mentor receives an appropriate reason and support path.
- Document rejected/unsafe: mentor receives a safe, non-sensitive explanation.

Persist in-app notification records even if email/push delivery fails. Delivery
jobs must be retryable and idempotent.

## Public Visibility and Booking Rules

All mentor discovery and booking code must enforce verification on the backend.
Hiding unverified mentors only in the mobile app is insufficient.

An unverified mentor must be excluded from:

- `GET /api/home/` featured mentors.
- `GET /api/mentors/` discovery and search.
- `GET /api/mentors/{id}/` public details, unless viewing their own preview.
- Public package and availability queries.
- New inquiry conversations if inquiries are limited to active mentors.
- Booking creation.

Recommended eligibility condition:

```text
user.is_active
AND user.role = mentor
AND mentor_application.status = verified
AND mentor_profile.is_active = true
AND mentor_profile.is_verified = true
```

Booking creation must recheck eligibility transactionally. A stale mobile screen
must not allow a booking after a mentor is suspended or unverified.

## Observability and Audit

Log structured events without logging tokens, passwords, document contents,
signed URLs, or sensitive identity data.

Useful metrics:

- Drafts created.
- Completion rate by step.
- Average time from registration to submission.
- Submission validation failure count by field.
- Pending review queue depth and oldest age.
- Average review duration.
- Approval, change-request, and rejection rates.
- Upload failures and malware-scan failures.
- API latency and error rate by endpoint.

Every request should carry or receive a `request_id` so mobile logs can be
matched to backend traces.

## Existing Endpoint Compatibility

The backend may internally reuse these existing resources after approval:

```text
PATCH /api/mentor-profiles/{mentor_id}/
POST  /api/packages/
POST  /api/availability-windows/
```

The mobile client should use the onboarding draft endpoint while onboarding so
partial setup does not expose half-created public resources. The backend can
materialize or activate profile, package, and availability records when the
application is approved.

Write-path items to verify during integration against the updated backend:

- Owner profile updates return `403 Permission denied`.
- Availability creation returns `401` with a valid mentor bearer token.

The first two permission rules need to be corrected if they are still
reproducible before connecting the prototype screens.

## Migration and Backward Compatibility

Existing mentor users may already have `MentorProfile`, package, and
availability records without an onboarding application. A data migration should
classify them deliberately instead of making them disappear from discovery.

Recommended migration:

1. Create a `MentorApplication` for every existing mentor user.
2. Copy available professional data, category/expertise relations, timezone,
   packages, and availability into the application or link them according to
   the chosen storage strategy.
3. Mark currently approved/live mentors as `verified` and set `submitted_at`
   and `reviewed_at` to the migration timestamp.
4. Mark incomplete/non-public mentor accounts as `draft`.
5. Record a `migrated` audit event with migration version.
6. Preserve all existing public IDs referenced by sessions, reviews, and
   conversations.

Do not infer verification from profile completeness alone. The product owner
should provide the rule or explicit list for which existing mentors are trusted
as verified.

For a staged rollout, protect the new behavior behind a backend feature flag.
Mentor and mentee registration must remain available throughout rollout.
Verification onboarding may be feature-flagged independently; a missing or
unfinished onboarding API must never block account/profile creation.

## Recommended Implementation Order

### Phase 1: Core Draft

1. Add application status enum, models, migrations, indexes, and admin display.
2. Change mentor registration to create user plus application draft atomically.
3. Implement owner `GET` and `PATCH` onboarding endpoints.
4. Add category/expertise references and full draft serialization.
5. Add object-level permissions and version conflict handling.

At the end of phase 1, the first two mobile screens can be connected and draft
resume can be tested.

### Phase 2: Services and Availability

1. Add draft package and availability child models.
2. Implement replacement/upsert semantics using `client_id`.
3. Add price, duration, timezone, overlap, and interval validation.
4. Verify no draft records leak through existing public endpoints.

### Phase 3: Secure Documents

1. Add document model and private storage integration.
2. Implement upload request, confirmation, deletion, and status serialization.
3. Add MIME detection, checksum verification, malware scanning, and retention.
4. Add audited reviewer download URLs.

### Phase 4: Submission and Review

1. Implement full submission validator and atomic status transition.
2. Add reviewer queue and application detail.
3. Add approve, request-changes, reject, and concurrency safeguards.
4. Materialize/activate production mentor records during approval.
5. Add notifications and review audit events.

### Phase 5: Enforcement and Rollout

1. Enforce verification in discovery, mentor detail, inquiry, availability, and
   booking queries.
2. Migrate existing mentor accounts.
3. Add dashboards, alerts, rate limits, and operational metrics.
4. Enable the feature flag for test users, then production mentors.

## Backend Test Plan

The backend implementation should include automated tests covering at least the
following cases.

### Registration

- Mentor registration creates one user and one draft in one transaction.
- Mentor registration accepts only account fields and creates a draft.
- Duplicate email does not create an orphan draft.
- Mentee registration does not create a mentor draft.
- Registration response includes role, tokens, and the onboarding summary.

### Draft Ownership and Saving

- Mentor can read and patch only their own application.
- Mentee and other mentors receive `403` or non-enumerating `404` as chosen.
- Partial scalar patch preserves omitted fields.
- Empty category/expertise list clears values.
- Supplied package/availability list uses documented replacement semantics.
- Retried `client_id` does not duplicate child records.
- Stale application version returns `409` without overwriting data.
- Pending, verified, and rejected applications cannot be edited.

### Validation

- Invalid reference IDs, URL schemes, prices, durations, timezones, weekdays,
  and overlapping windows return field-addressable errors.
- Draft can remain incomplete.
- Submission returns all missing required sections in one `422` response.
- Terms version mismatch blocks submission.
- A valid application transitions exactly once to pending review.

### Documents

- Upload URL belongs only to the requesting application and expires.
- File size and detected MIME type are enforced.
- Confirmation checks object existence and checksum.
- Unsafe or scanning documents do not satisfy submission requirements.
- Another user cannot confirm, delete, or download a document.
- Reviewer download creates an audit event and uses a short-lived URL.

### Review

- Only reviewer/staff permissions can access the queue and decision endpoints.
- Two concurrent decisions produce one winner and one `409` conflict.
- Change request exposes notes/field paths and re-enables mentor edits.
- Resubmission returns to pending review and creates one audit event.
- Approval activates one profile and the expected package/availability records.
- Retrying approval does not duplicate production records or notifications.
- Rejected applications cannot be edited or submitted.

### Public Enforcement

- Draft, pending, change-requested, rejected, and suspended mentors do not appear
  in home/discovery.
- Unverified mentor detail and booking requests are denied server-side.
- Verified mentors appear with only active packages and availability.
- Removing verification immediately prevents new bookings.
- Historical sessions, reviews, and conversations remain readable according to
  their existing permissions.

## Definition of Done

The backend feature is ready for mobile integration when all of the following
are true:

- Mentor registration creates the account and onboarding draft in one call.
- Registration creates and returns a resumable draft.
- All six mobile screens can save and reload their data.
- Proof files are private, scanned, and accessible to reviewers only through
  audited short-lived URLs.
- Full submission validation returns stable field paths understood by mobile.
- A submitted draft becomes immutable until a reviewer requests changes.
- Reviewer actions are permission-protected, atomic, and audited.
- Approval makes the mentor discoverable and bookable without manual database
  edits.
- Non-verified mentors are blocked from every public discovery and booking path.
- Existing mentors are migrated without breaking historical data.
- Endpoint tests, permission tests, transition tests, and concurrency tests pass.
- API documentation/OpenAPI examples reflect the final payloads.
- Backend staging data demonstrates draft, pending, changes-requested, verified,
  and rejected accounts.

## Decisions Needed From Product/Backend

Before final implementation, confirm these points:

1. Is government ID mandatory, or is professional evidence sufficient?
2. Which professions and categories are supported at launch?
3. What minimum and maximum package prices are allowed?
4. Can mentors use the dashboard while pending, and which sections are visible?
5. Can a rejected applicant appeal or restart after a cooldown period?
6. What review notes are safe to expose directly to mentors?
7. What is the document retention period for verified, rejected, and abandoned
   applications?
8. Which staff roles may review identity documents?
9. Are company-email or LinkedIn verification alternatives planned?
10. Should verified-profile edits to sensitive fields trigger re-review later?

These decisions should be configuration or explicit policy where possible, not
duplicated as assumptions in the mobile application.
