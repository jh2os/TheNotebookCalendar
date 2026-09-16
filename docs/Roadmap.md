# Digital Pencil-and-Paper Calendar

## 1. Product Goal

Build a simple digital calendar that behaves more like a paper calendar than a traditional scheduling application.

The core concept is:

> A calendar consists of days, and each day can contain one freeform text note.

There are intentionally **no events, appointments, reminders, invitations, recurring events, time slots, or scheduling features** in the initial application.

A user can:

* Log in using a magic link sent to their email.
* Create multiple calendars.
* View a calendar by month or week.
* Select any day.
* Enter or edit one text note associated with that day.
* Share a calendar with other users.
* Manage the users who have access to a calendar if they are the calendar's primary creator.
* Log out.
* Use the application comfortably on desktop and mobile.
* Switch between light and dark mode.

---

# 2. Technology

## Backend

* Ruby on Rails
* PostgreSQL
* Rails JSON API
* Rails Active Record
* Rails session-based authentication
* Rails mailer for magic-link authentication
* RSpec or another Rails test framework
* Request/integration tests for API behavior

## Frontend

* Vue.js
* Vue Router where routing is useful
* Fetch/Axios for API communication
* Component-based calendar UI
* Responsive CSS
* Client-side light/dark theme handling

## Architectural Direction

The recommended architecture is:

```text
Browser
   |
   | HTTPS / JSON API
   v
Vue.js Application
   |
   | Cookie-based session
   v
Rails Application
   |
   v
PostgreSQL
```

The application should use **server-side/session-based authentication rather than JWTs** for the initial version.

This keeps authentication relatively simple and gives the application a conventional browser session that can be invalidated when the user logs out.

---

# 3. Core Domain Model

The initial database model should contain four primary concepts.

## User

Represents an authenticated person.

Suggested fields:

* `id`
* `email`
* `created_at`
* `updated_at`

Requirements:

* Email must be unique.
* Email comparisons should be normalized/case-insensitive.
* A user can belong to many calendars.

---

## Calendar

Represents a collection of dated notes.

Suggested fields:

* `id`
* `name`
* `created_by_id`
* `created_at`
* `updated_at`

Requirements:

* A calendar must have a name.
* A calendar has exactly one primary creator.
* The creator must automatically receive access when the calendar is created.
* A user can create multiple calendars.

---

## Calendar Membership

Join table between users and calendars.

Suggested fields:

* `id`
* `calendar_id`
* `user_id`
* `role`
* `created_at`
* `updated_at`

The initial roles should be:

* `owner`
* `member`

Requirements:

* A user cannot have duplicate memberships in the same calendar.
* Only the owner can add or remove other members.
* The owner cannot accidentally remove their own ownership.
* Membership removal immediately prevents access to the calendar.
* Authorization must be enforced by Rails, not just hidden in the Vue UI.

A database uniqueness constraint should exist for:

```text
calendar_id + user_id
```

---

## Daily Note

Represents the single piece of text associated with a calendar day.

Suggested fields:

* `id`
* `calendar_id`
* `date`
* `body`
* `created_at`
* `updated_at`

The `date` field should be a PostgreSQL `DATE`, **not a timestamp**.

This is an important design decision.

A calendar note belongs to a calendar day, not a moment in time. Using a timestamp would introduce unnecessary timezone problems.

The combination:

```text
calendar_id + date
```

must be unique.

Therefore a calendar can have:

```text
2026-09-16 -> "Buy groceries"
2026-09-17 -> "Call Mom"
2026-09-18 -> "Finish project"
```

but can never have two separate notes for `2026-09-16`.

---

# 4. Calendar Date Semantics

The application should treat calendar days as date-only values.

The API should use ISO date strings:

```text
2026-09-16
```

rather than JavaScript/Ruby datetime values.

This avoids common bugs where:

* the browser is in one timezone,
* the Rails server is in another,
* PostgreSQL is storing UTC,
* and the displayed day shifts unexpectedly.

The Vue application should generate the visible month/week from date values rather than using timestamps for day identity.

---

# 5. Calendar Views

## Monthly View

Monthly view is the default.

The month view should:

* Show all days in the selected month.
* Visually distinguish today.
* Allow selecting a day.
* Indicate which days contain notes.
* Allow navigation to previous/next month.
* Allow returning to the current month.
* Work on desktop and mobile.
* Avoid requiring horizontal scrolling on normal mobile screen sizes.

The exact week-start convention should be centralized rather than scattered throughout the codebase.

---

## Weekly View

Weekly view should:

* Show seven consecutive days.
* Allow navigation to previous/next week.
* Allow selecting a day.
* Indicate whether each day contains a note.
* Preserve the same note-editing behavior as monthly view.
* Work on desktop and mobile.

The underlying note API should not care whether the user is viewing a week or a month.

Both views should ultimately request notes for a date range.

For example:

```text
GET /api/calendars/:calendar_id/notes?start_date=2026-09-01&end_date=2026-09-30
```

This prevents the frontend from making one API request per day.

---

# 6. Note Editing Behavior

Selecting a day should present a simple text editing experience.

The initial implementation should deliberately remain simple:

* One text area.
* Existing note is loaded when a day is selected.
* Blank days show an empty text area.
* Save creates or updates the note.
* Saving an empty note should remove the note or result in no stored note.
* The UI should clearly show whether changes have been saved.

Automatic autosave should **not** be required for the first implementation unless it is later determined to significantly improve usability.

This keeps the initial application predictable and reduces accidental writes.

---

# 7. Authentication

Authentication will use passwordless magic links.

## Login flow

1. User enters their email address.
2. Rails creates a short-lived, single-use authentication token.
3. An email containing the magic link is sent.
4. User clicks the link.
5. Rails verifies the token.
6. Rails creates an authenticated session.
7. User is redirected into the Vue application.
8. The token is invalidated.

Requirements:

* Tokens must expire.
* Tokens must be single-use.
* Tokens should be stored securely rather than storing a reusable plaintext credential.
* Attempting to reuse an expired or consumed token must fail.
* Login should not reveal whether an arbitrary email address has an existing account.
* Logging out must invalidate the authenticated session.

A development environment should provide a convenient way to inspect outgoing emails without requiring a real email provider.

---

# 8. Authorization

Authorization must exist on the backend.

The Vue application may hide controls from unauthorized users, but that is only a UI convenience.

Rails must independently verify:

* The current user is authenticated.
* The current user has access to the requested calendar.
* The current user owns the calendar before allowing membership changes.
* A user cannot read notes from a calendar they do not belong to.
* A user cannot modify notes on a calendar they do not belong to.
* A user cannot modify another calendar's memberships.

Every relevant API endpoint should perform authorization checks.

---

# 9. Calendar Membership

The owner should have a simple people-management interface.

The owner can:

* View current members.
* Add another user by email.
* Remove another user.

For the initial implementation, adding a person should target an existing user account.

Do **not** introduce invitations, invitation acceptance workflows, or email-based calendar invitations unless they become an explicit future requirement.

If the specified email does not correspond to an existing user, the UI should provide a clear message rather than silently creating an account.

---

# 10. API Principles

The API should be REST-like and predictable.

Suggested resources:

```text
POST   /api/auth/magic_links
GET    /api/auth/magic_links/:token
DELETE /api/session

GET    /api/me

GET    /api/calendars
POST   /api/calendars
GET    /api/calendars/:id
PATCH  /api/calendars/:id
DELETE /api/calendars/:id

GET    /api/calendars/:id/members
POST   /api/calendars/:id/members
DELETE /api/calendars/:id/members/:user_id

GET    /api/calendars/:id/notes
GET    /api/calendars/:id/notes/:date
PUT    /api/calendars/:id/notes/:date
DELETE /api/calendars/:id/notes/:date
```

The exact endpoint design can be adjusted during implementation, but the conceptual separation should remain.

---

# 11. Database and Scaling Requirements

The application is expected to start small but should not make obvious scaling mistakes.

Required indexes/constraints should include:

### Users

```text
unique index on email
```

### Calendars

```text
index on created_by_id
```

### Calendar Memberships

```text
unique index on (calendar_id, user_id)
index on user_id
```

### Notes

```text
unique index on (calendar_id, date)
```

The notes index is particularly important because the primary access pattern will be:

```text
Give me all notes for calendar X between date A and date B.
```

The composite index on:

```text
(calendar_id, date)
```

supports that access pattern directly.

Avoid adding indexes that do not support a real query pattern. More indexes are not automatically better because each index adds write and storage overhead.

---

# 12. Common Definition of Done

Every PR should:

* Have one clearly defined responsibility.
* Include automated tests for new behavior.
* Avoid unrelated refactoring.
* Avoid introducing dependencies without a reason.
* Include database migrations when needed.
* Preserve backward compatibility with previous PRs.
* Leave the application in a runnable state.
* Update relevant documentation when behavior changes.
* Keep business logic out of Vue where it belongs on the Rails side.
* Keep authorization enforcement on the Rails side.
* Prefer small, composable Vue components.

An AI coding agent should not be asked to implement an entire feature spanning backend, database, frontend, styling, and deployment in one PR unless there is a specific reason.

---

# 13. PR / Planning Ticket Roadmap

## PR-01 — Bootstrap the Application

### Goal

Create the basic Rails + Vue application structure and development workflow without implementing meaningful product functionality.

### Scope

* Create Rails application.
* Configure PostgreSQL.
* Configure Vue.
* Establish API/frontend boundary.
* Establish development commands.
* Establish automated test framework.
* Add linting/formatting.
* Add basic CI.
* Add environment configuration conventions.
* Add a simple health endpoint.

### Acceptance Criteria

* Application can be started locally.
* Rails can connect to PostgreSQL.
* Vue application loads successfully.
* Vue can make a request to Rails.
* Automated tests execute successfully.
* CI runs tests/linting.
* No authentication or calendar functionality is implemented yet.

### Out of Scope

* Users
* Authentication
* Calendars
* Notes
* Styling beyond minimal application bootstrapping

### Review Focus

This PR should establish the architecture only. Avoid allowing application scaffolding to grow into product code.

---

# PR-02 — Implement Core Database Models

### Goal

Create the persistent domain model for users, calendars, memberships, and daily notes.

### Scope

Create:

* `users`
* `calendars`
* `calendar_memberships`
* `daily_notes`

Add:

* Active Record associations.
* Validations.
* Foreign keys.
* Database constraints.
* Required indexes.
* Model tests.

### Acceptance Criteria

* Database can be migrated from an empty database.
* Foreign key relationships are enforced.
* User email is unique.
* Calendar membership is unique per user/calendar.
* Daily note is unique per calendar/date.
* A note uses a PostgreSQL `DATE`.
* Model tests cover the important constraints.

### Out of Scope

* Authentication
* Controllers
* Vue UI
* Calendar creation workflows

### Review Focus

Pay particular attention to database constraints. Application-level validation alone should not be relied upon for uniqueness.

---

# PR-03 — Magic Link Authentication

### Goal

Implement passwordless login and logout.

### Scope

* Magic-link request endpoint.
* Secure token generation.
* Token expiration.
* Single-use tokens.
* Email delivery.
* Session creation.
* Current-user endpoint.
* Logout endpoint.
* Authentication middleware/helper.

### Acceptance Criteria

A user can:

1. Enter an email.
2. Receive a login link in development/test email output.
3. Follow the link.
4. Become authenticated.
5. Access authenticated endpoints.
6. Log out.
7. No longer access authenticated endpoints.

Invalid, expired, and reused tokens must fail safely.

### Security Requirements

* Token must be cryptographically random.
* Token should not be stored as reusable plaintext authentication material.
* Token must have a limited lifetime.
* Token must be invalidated after successful use.
* Authentication state must be stored in a secure session cookie.
* CSRF/session protections must be considered for the chosen Rails architecture.

### Out of Scope

* Calendar permissions
* Calendar UI

---

# PR-04 — Calendar Creation and Ownership

### Goal

Allow authenticated users to create and manage their calendars.

### Scope

Implement:

* Create calendar.
* List calendars available to current user.
* Read calendar details.
* Rename calendar.
* Delete calendar.
* Automatic owner membership when creating a calendar.

### Acceptance Criteria

* Authenticated users can create multiple calendars.
* Creator automatically receives owner access.
* Users can only see calendars they belong to.
* Users cannot access another user's calendar by changing an ID in the URL.
* Calendar deletion handles associated memberships and notes correctly.

### Review Focus

Confirm that authorization is implemented at the Rails API layer.

---

# PR-05 — Calendar Membership Management

### Goal

Allow calendar owners to control who has access to a calendar.

### Scope

Implement:

* List calendar members.
* Add existing user by email.
* Remove member.
* Owner/member role handling.
* Authorization rules.

### Acceptance Criteria

* Owner can see all members.
* Owner can add an existing user.
* Owner can remove another member.
* Members cannot modify membership.
* Members cannot remove the owner.
* Owner cannot accidentally remove their own ownership.
* Unauthorized membership operations return appropriate HTTP errors.

### Out of Scope

* Invitation emails
* Pending invitations
* Role hierarchy beyond owner/member

### Review Focus

Most of this PR should be backend authorization rather than UI.

---

# PR-06 — Daily Notes API

### Goal

Implement the API for reading and writing one note per calendar day.

### Scope

Implement:

* Retrieve notes for a date range.
* Retrieve a single day's note.
* Create/update a day's note.
* Delete a day's note.
* Calendar membership authorization.

### Recommended API Behavior

For range queries:

```text
GET /api/calendars/:id/notes?start_date=2026-09-01&end_date=2026-09-30
```

For a single day:

```text
GET /api/calendars/:id/notes/2026-09-16
```

Writing:

```text
PUT /api/calendars/:id/notes/2026-09-16
```

### Acceptance Criteria

* A calendar cannot contain two notes for one date.
* Creating a note works.
* Updating an existing note works.
* Deleting a note works.
* Empty notes do not leave unwanted empty records.
* Range requests return only the requested calendar/date range.
* Unauthorized users cannot read or modify notes.

### Performance Requirement

The monthly/week queries should result in a small number of database queries and should use the `(calendar_id, date)` index.

---

# PR-07 — Calendar Month View

### Goal

Build the first usable calendar interface.

### Scope

Implement the default monthly calendar view.

Include:

* Current month.
* Previous/next month.
* Current-day highlighting.
* Seven-day week layout.
* Day selection.
* Note indicators.
* Calendar selection.

### Acceptance Criteria

* User can select a calendar.
* Current month is displayed by default.
* User can navigate between months.
* Days with notes are visually distinguishable.
* Selecting a day exposes the selected day to the rest of the application.
* Notes are loaded using a range request rather than one request per day.

### Out of Scope

* Editing note text
* Weekly view
* Dark mode

This PR should focus on rendering the calendar correctly.

---

# PR-08 — Day Note Editor

### Goal

Connect the selected calendar day to the daily note API.

### Scope

Implement:

* Note editor component.
* Loading the selected day's note.
* Saving a note.
* Updating a note.
* Deleting/clearing a note.
* Saved/unsaved UI state.
* Loading and error states.

### Acceptance Criteria

Selecting a day allows the user to:

```text
select day
    ↓
see existing note
    ↓
edit text
    ↓
save
    ↓
see note reflected on calendar
```

For an empty day:

```text
select day
    ↓
empty editor
    ↓
enter text
    ↓
save
    ↓
day displays as containing a note
```

### Review Focus

Keep the note editor independent of the month calendar component as much as practical.

---

# PR-09 — Weekly Calendar View

### Goal

Add an alternative weekly view using the same underlying note components/API.

### Scope

Implement:

* Seven-day weekly view.
* Previous/next week.
* Current-week navigation.
* Day selection.
* Existing note indicators.
* Reuse of the note editor.

### Acceptance Criteria

* User can switch between month and week.
* Both views display the same underlying notes.
* Editing a note in one view immediately appears in the other after refresh/state update.
* Weekly view uses one date-range request rather than seven day requests.

### Review Focus

The weekly view should consume the existing calendar/note abstractions rather than creating a parallel implementation.

---

# PR-10 — Responsive Desktop and Mobile UX

### Goal

Make the application comfortable to use on both desktop and mobile screens.

### Scope

Review and improve:

* Month layout.
* Week layout.
* Day selection.
* Note editor.
* Navigation controls.
* Calendar selector.
* Member-management UI.

### Desktop Requirements

* Calendar should make good use of available screen width.
* Note editor should not obscure the calendar unnecessarily.
* Navigation controls should be easy to discover.

### Mobile Requirements

* No unnecessary horizontal scrolling.
* Touch targets should be comfortably tappable.
* Calendar cells should remain usable at narrow widths.
* Note editor should fit naturally on small screens.
* Navigation should remain accessible.

### Acceptance Criteria

Test at minimum:

* Typical desktop width.
* Tablet width.
* Typical mobile width.
* Narrow mobile width.

No functionality should depend on hover.

---

# PR-11 — Light and Dark Mode

### Goal

Add application-wide theme support.

### Scope

Implement:

* Light theme.
* Dark theme.
* Theme switcher.
* Persist user preference locally.
* Respect system preference initially where appropriate.

### Acceptance Criteria

* User can switch between themes.
* Calendar remains legible in both.
* Note editor remains legible in both.
* Buttons and controls have accessible contrast.
* Theme preference survives page reload.
* Switching themes does not require reloading the page.

### Review Focus

Avoid scattering theme-specific logic across Vue components. Prefer centralized theme variables/tokens.

---

# PR-12 — User and Calendar Management UI

### Goal

Provide the remaining user-facing management screens.

### Scope

Implement:

* Calendar list.
* Calendar creation UI.
* Calendar rename UI.
* Calendar deletion confirmation.
* Member list.
* Add member.
* Remove member.
* Owner-only controls.
* Logout.

### Acceptance Criteria

A typical user workflow is complete:

```text
Login
  ↓
See calendars
  ↓
Create/select calendar
  ↓
View month
  ↓
Select day
  ↓
Write note
  ↓
Save
  ↓
Switch views
  ↓
Logout
```

An owner workflow is complete:

```text
Open calendar
  ↓
Manage members
  ↓
Add member
  ↓
Remove member
```

---

# PR-13 — Authorization, Security, and Integration Hardening

### Goal

Perform a dedicated pass over security and cross-feature behavior rather than allowing security concerns to be buried inside individual PRs.

### Scope

Add automated tests covering:

* Unauthenticated requests.
* Unauthorized calendar access.
* Unauthorized note access.
* Unauthorized membership management.
* Expired magic links.
* Reused magic links.
* Session logout.
* Cross-calendar data leakage.
* Attempted duplicate memberships.
* Attempted duplicate daily notes.
* Calendar deletion behavior.

### Acceptance Criteria

A user must never be able to access another calendar's:

* Metadata
* Members
* Notes

by changing IDs or dates in API requests.

### Review Focus

This PR should include adversarial tests that intentionally attempt operations the UI would normally prevent.

---

# PR-14 — End-to-End User Flows and Final Polish

### Goal

Verify that the application works as a cohesive product rather than merely as individual tested components.

### Scope

Create end-to-end tests covering:

### Flow A — New User

```text
Request magic link
→ login
→ create calendar
→ view month
→ write note
→ refresh page
→ note still exists
```

### Flow B — Existing User

```text
Login
→ select existing calendar
→ navigate month
→ navigate week
→ edit note
→ change theme
→ logout
```

### Flow C — Sharing

```text
Owner
→ add member
→ member logs in
→ member sees shared calendar
→ member edits note
→ owner sees change
```

### Flow D — Security

```text
Member
→ attempts membership administration
→ denied

Non-member
→ attempts calendar access
→ denied
```

### Acceptance Criteria

All core workflows work from the browser without relying on development-only shortcuts.

---

# PR-15 — Production Readiness and Documentation

### Goal

Make the application understandable and deployable by someone other than the original developer/AI agent.

### Scope

Document:

* Local development setup.
* Database setup.
* Environment variables.
* Email configuration.
* Production deployment.
* Database migrations.
* Test commands.
* Frontend build process.
* Authentication architecture.
* Database schema.
* Authorization model.
* API conventions.

Add:

* Production environment configuration.
* Error logging.
* Appropriate health check.
* Database migration procedure.
* Production-safe secret management.

### Acceptance Criteria

A new developer should be able to read the repository documentation and understand how to:

1. Start the project.
2. Run the tests.
3. Run migrations.
4. Configure email.
5. Build the frontend.
6. Deploy the application.

---

# 14. Suggested PR Merge Sequence

The intended dependency chain is:

```text
PR-01  Application bootstrap
   ↓
PR-02  Database/domain model
   ↓
PR-03  Authentication
   ↓
PR-04  Calendar ownership
   ↓
PR-05  Calendar membership
   ↓
PR-06  Notes API
   ↓
PR-07  Month view
   ↓
PR-08  Note editor
   ↓
PR-09  Week view
   ↓
PR-10  Responsive UX
   ↓
PR-11  Theme
   ↓
PR-12  Management UI
   ↓
PR-13  Security hardening
   ↓
PR-14  End-to-end validation
   ↓
PR-15  Production readiness
```

This ordering deliberately moves from:

```text
infrastructure
→ data
→ authentication
→ authorization
→ API
→ UI
→ polish
→ hardening
→ deployment
```

That makes failures much easier to isolate.

---

# 15. Recommended AI Coding-Agent Rules

The coding agent should be given a few additional constraints.

## Rule 1 — Do Not Expand PR Scope

When working on a ticket, implement only the requirements of that ticket.

Do not proactively implement future tickets.

For example, while implementing the month view, do not also build:

* weekly view,
* dark mode,
* member management,
* autosave,
* calendar sharing UI.

Those belong to later PRs.

---

## Rule 2 — Preserve Existing Behavior

Every PR should treat the previous PR as a working baseline.

Do not solve a new problem by rewriting existing working code unless the ticket specifically requires it.

---

## Rule 3 — Prefer Small Components

Vue components should have narrow responsibilities.

For example:

```text
CalendarPage
 ├── CalendarHeader
 ├── CalendarToolbar
 ├── MonthView
 │    └── CalendarDay
 └── DayNoteEditor
```

The exact component structure can evolve, but the application should avoid one giant calendar component containing navigation, data fetching, note editing, membership management, and theme logic.

---

## Rule 4 — Keep Business Rules on the Server

The frontend should not be trusted to enforce rules such as:

```text
"Only owners can add members."
```

Vue should hide inappropriate controls, but Rails must enforce the rule.

---

## Rule 5 — Test the Business Rules

Tests should concentrate on behavior that matters.

Examples:

```text
A calendar member can read notes.
A non-member cannot.
An owner can add members.
A normal member cannot.
A calendar cannot have two notes for the same date.
An expired login token cannot authenticate.
```

Do not spend large amounts of test code verifying implementation details that are free to change.

---

# 16. Explicit Non-Goals

The following should remain outside the initial project unless requirements change:

* Events
* Event start/end times
* Reminders
* Recurring events
* Calendar invitations
* External calendar synchronization
* Google/Apple/Microsoft calendar integration
* Notifications
* Push notifications
* Drag-and-drop scheduling
* Time-zone-aware appointments
* Multiple notes per day
* Rich text editing
* Attachments
* Checklists
* Sharing individual days
* Public calendars
* Calendar publishing
* Complex permission hierarchies

The application's strength should come from doing one thing very well:

> A simple shared calendar where every day is a piece of paper you can write on.
