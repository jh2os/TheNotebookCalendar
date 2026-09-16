# AI Coding Guide

## Purpose

This document provides instructions for AI coding agents working on this repository.

The agent must treat this document as a set of engineering constraints, not merely suggestions.

The application is a simple digital equivalent of a pencil-and-paper calendar.

The core product behavior is:

> A calendar contains one freeform text note for each calendar day.

The application intentionally does not provide traditional scheduling functionality.

---

# 1. Primary Engineering Principles

## 1.1 Make the smallest change necessary

For every task:

* Implement only the requested functionality.
* Do not implement future features.
* Do not perform unrelated refactoring.
* Do not replace working code merely because another approach is preferred.
* Do not introduce abstractions until they are justified by the current codebase.

Prefer:

```text
small change
→ focused tests
→ review
→ merge
```

over:

```text
large architectural improvement
→ many unrelated changes
→ difficult review
```

---

## 1.2 One PR should solve one problem

A pull request should have one primary responsibility.

A PR may contain changes across Rails, Vue, database migrations, and tests if those changes are necessary to implement the ticket.

A PR should not combine unrelated features.

Example:

### Good

```text
Add daily note API
```

May contain:

* database changes
* Rails model logic
* controller
* authorization
* request tests

### Bad

```text
Add daily note API
+ redesign authentication
+ introduce dark mode
+ refactor Vue components
+ change deployment
```

---

## 1.3 Preserve a working application

After every ticket:

* The application should boot.
* Tests should pass.
* Existing functionality should continue working.
* Database migrations should execute successfully from a clean database.
* The frontend should build successfully.

Do not leave partially implemented functionality unless the ticket explicitly requires it.

---

# 2. Technology Constraints

## Backend

Use:

* Ruby
* Ruby on Rails
* PostgreSQL

Prefer standard Rails functionality over additional dependencies.

Before adding a gem, determine whether Rails already provides the necessary capability.

---

## Frontend

Use:

* Vue.js
* JavaScript or TypeScript according to the repository's established convention.

Once the repository has established a language choice, do not switch languages without an explicit ticket.

---

## Database

Use PostgreSQL.

Use PostgreSQL-native types when they accurately represent the domain.

For calendar days:

```ruby
date
```

must be used rather than a timestamp.

---

# 3. Repository Structure

The exact directory structure may evolve, but maintain a clear separation between:

```text
backend/domain
backend/api
frontend/components
frontend/views
frontend/services
tests
```

Frontend components should be responsible primarily for presentation and user interaction.

Backend code should own:

* authentication
* authorization
* validation of business rules
* persistence
* data integrity

---

# 4. Domain Rules

These rules are authoritative.

## 4.1 Users

A user is identified by email.

Requirements:

* Email is unique.
* Email should be normalized consistently.
* Authentication is passwordless.

Do not add passwords unless explicitly requested.

---

## 4.2 Calendars

A user may own multiple calendars.

A calendar has exactly one owner.

A calendar may have multiple members.

The owner is also a member.

---

## 4.3 Membership

Membership represents access to a calendar.

Initial roles:

```text
owner
member
```

Rules:

* A user may have at most one membership for a calendar.
* Only the owner may add members.
* Only the owner may remove members.
* The owner cannot remove themselves through normal member removal.
* Backend authorization is authoritative.

Do not rely on Vue to enforce these rules.

---

## 4.4 Daily Notes

A calendar may contain at most one note for a given date.

The identity of a note is:

```text
calendar_id + date
```

This rule must be enforced by PostgreSQL with a unique constraint/index.

A note belongs to a calendar day, not a time.

The application should therefore use:

```text
2026-09-16
```

rather than:

```text
2026-09-16T00:00:00Z
```

for day identity.

---

# 5. Date and Time Rules

Calendar dates are date-only values.

Do not convert calendar dates through JavaScript `Date` objects unnecessarily.

Avoid logic equivalent to:

```javascript
new Date("2026-09-16")
```

when a date-only operation is intended.

This can introduce timezone-related day shifts.

Prefer a date representation that preserves:

```text
YYYY-MM-DD
```

through the full request/response path.

---

# 6. Authentication Rules

Authentication uses magic links.

## Login

The expected flow is:

```text
email
↓
request magic link
↓
secure short-lived token
↓
email
↓
token verification
↓
authenticated session
```

Authentication tokens must:

* be cryptographically random
* expire
* be single-use
* not be reusable after successful authentication

Do not expose authentication secrets in logs.

Do not commit secrets.

---

## 6.1 Session Handling

Use the simplest secure session mechanism appropriate for Rails.

The initial application should prefer server-backed/session-based browser authentication over introducing JWTs without an explicit requirement.

---

## 6.2 Logout

Logout must invalidate the authenticated session.

After logout, authenticated API requests must no longer succeed.

---

# 7. Authorization Rules

Every protected backend operation must explicitly determine whether the current user is allowed to perform it.

Never rely solely on:

```text
frontend visibility
```

for authorization.

For every protected resource, verify:

```text
authenticated?
+
authorized for this specific resource?
```

A user must not gain access merely by changing:

```text
/calendar/123
```

to:

```text
/calendar/124
```

in a request.

---

# 8. API Rules

The API should use consistent JSON responses and HTTP semantics.

Prefer resource-oriented endpoints.

For example:

```text
GET /api/calendars
POST /api/calendars

GET /api/calendars/:id/notes
GET /api/calendars/:id/notes/:date
PUT /api/calendars/:id/notes/:date
DELETE /api/calendars/:id/notes/:date
```

Do not introduce substantially different API conventions for individual features.

---

## 8.1 Date Range Queries

Calendar views should retrieve notes in ranges.

Example:

```http
GET /api/calendars/123/notes?start_date=2026-09-01&end_date=2026-09-30
```

Do not make one HTTP request per calendar day.

A month should normally require one notes request.

A week should normally require one notes request.

---

# 9. Database Rules

Database constraints are part of the application's business logic.

Do not rely solely on Rails model validations for rules involving uniqueness.

Required examples:

```text
users.email
    UNIQUE

calendar_memberships(calendar_id, user_id)
    UNIQUE

daily_notes(calendar_id, date)
    UNIQUE
```

Use foreign keys where appropriate.

---

# 10. Indexing Rules

Indexes should support actual access patterns.

Required important indexes include:

```text
users(email)

calendars(created_by_id)

calendar_memberships(calendar_id, user_id)

calendar_memberships(user_id)

daily_notes(calendar_id, date)
```

Before adding an index, identify the query it supports.

Do not add arbitrary indexes solely because "more indexes improve performance."

---

# 11. Vue Architecture Rules

Prefer small components with one responsibility.

A reasonable conceptual structure is:

```text
CalendarPage
├── CalendarHeader
├── CalendarToolbar
├── MonthView
│   └── CalendarDay
├── WeekView
└── DayNoteEditor
```

The actual names may differ.

Avoid a single large component responsible for:

* API calls
* calendar rendering
* membership management
* authentication
* note editing
* theme management

---

# 12. Vue State Rules

Use local component state when state is local.

Use shared state only when multiple unrelated parts of the application genuinely need the same state.

Do not introduce a global state framework merely because it is available.

Prefer straightforward data flow.

---

# 13. API Client Rules

Frontend API communication should be centralized or consistently organized.

Avoid scattering raw HTTP requests throughout dozens of components.

Prefer something conceptually similar to:

```text
services/
    auth
    calendars
    notes
    members
```

The precise implementation is up to the repository.

---

# 14. Error Handling

Every API operation should account for:

* success
* validation failure
* authentication failure
* authorization failure
* unexpected server failure
* network failure where relevant

The frontend should provide useful user feedback.

Do not silently swallow errors.

Do not expose backend stack traces to users.

---

# 15. Loading States

Every async operation that can take noticeable time should have an appropriate loading state.

Examples:

* login request
* calendar loading
* note loading
* note saving
* member addition
* member removal

Do not let users repeatedly submit the same operation because the UI gives no indication that a request is in progress.

---

# 16. Calendar UX Rules

The default view is monthly.

The application also supports weekly view.

Both views must:

* allow selecting a day
* identify today
* indicate days containing notes
* navigate backward/forward
* work without hover
* work with touch input

The calendar must remain usable on small screens.

---

# 17. Note Editing Rules

There is exactly one note per calendar day.

The editor should support:

* empty note
* creating note
* editing note
* clearing note

An empty note should not result in a meaningless persistent database row.

Unless a ticket explicitly introduces autosave, use explicit save behavior.

Do not introduce autosave accidentally.

---

# 18. Responsive Design Rules

The application must work on:

* desktop
* tablet
* mobile

Do not design desktop first and treat mobile as an afterthought.

Do not depend on:

```text
:hover
```

for essential functionality.

Touch targets should be sufficiently large for ordinary mobile interaction.

---

# 19. Theme Rules

The application supports:

* light mode
* dark mode

Theme state should be centrally managed.

Prefer shared CSS variables/design tokens rather than hard-coding theme decisions inside individual components.

Example conceptual tokens:

```css
--background
--foreground
--surface
--border
--accent
--muted
```

Exact values are implementation details.

---

# 20. Testing Philosophy

Tests should verify behavior rather than implementation details.

Prioritize:

1. Business rules
2. Authorization
3. API behavior
4. Important UI behavior
5. End-to-end workflows

---

## 20.1 Backend Tests

For important Rails behavior, test:

* model constraints
* authorization
* API responses
* authentication
* database behavior

Example:

```text
member can read calendar
non-member cannot read calendar

owner can add member
member cannot add member

one daily note per date
duplicate note rejected
```

---

## 20.2 Frontend Tests

Test important user-visible behavior.

Examples:

```text
selecting a day displays its note
saving a note updates the UI
month navigation changes the displayed date range
weekly view displays seven days
theme toggle changes theme
```

Do not heavily test internal component structure unless necessary.

---

## 20.3 End-to-End Tests

Use end-to-end tests for critical workflows.

At minimum:

```text
login
→ create calendar
→ create note
→ reload
→ note persists
```

and:

```text
owner
→ add member
→ member accesses calendar
→ member edits note
```

---

# 21. Security Rules

Never commit:

* API keys
* passwords
* session secrets
* magic-link tokens
* production credentials

Do not print authentication tokens in logs.

Do not return sensitive authentication information in JSON.

Treat all frontend-provided IDs as untrusted input.

Validate:

* dates
* IDs
* email addresses
* note content
* membership operations

---

# 22. Dependency Rules

Before adding a dependency:

1. Determine whether Rails/Vue/browser APIs already provide the capability.
2. Determine whether an existing dependency already solves the problem.
3. Consider maintenance and security impact.
4. Add the dependency only when it materially simplifies or improves the implementation.

Avoid adding dependencies merely because an AI agent is familiar with them.

---

# 23. Refactoring Rules

Do not refactor unrelated code during feature work.

A refactor is appropriate when:

* the current code directly prevents implementation of the ticket
* the refactor removes duplication introduced by the ticket
* the refactor materially improves correctness

Otherwise create a separate ticket.

---

# 24. AI Agent Workflow

For every ticket, follow this sequence.

## Step 1 — Read

Before modifying code:

* Read this document.
* Read the ticket.
* Inspect existing implementation relevant to the ticket.
* Identify existing tests.
* Identify dependencies on previous features.

Do not assume the repository matches the ticket description perfectly.

---

## Step 2 — Plan

Before writing code, identify:

```text
Files to change
Database changes
Backend changes
Frontend changes
Tests required
Potential risks
```

Keep the plan proportional to the task.

---

## Step 3 — Implement

Make the smallest complete implementation.

Do not implement future functionality.

Do not rewrite unrelated code.

---

## Step 4 — Test

Run:

* relevant targeted tests first
* full test suite afterward
* linting/formatting
* frontend build if applicable

Fix failures introduced by the current change.

---

## Step 5 — Review Your Own Diff

Before considering the ticket complete, inspect the complete diff.

Ask:

```text
Did I change anything unrelated?

Did I accidentally implement future functionality?

Did I introduce unnecessary dependencies?

Did I add tests for the important behavior?

Did I preserve authorization?

Did I preserve database constraints?

Did I create timezone/date handling problems?

Did I leave debugging code behind?
```

---

## Step 6 — Report

The final implementation report should contain:

```text
Implemented:
- ...

Tests:
- ...

Database:
- ...

Not implemented because out of scope:
- ...

Potential follow-up:
- ...
```

Do not claim tests passed unless they were actually run.

---

# 25. Ticket Execution Contract

When given a ticket, the agent must interpret the ticket as the scope boundary.

The agent may make supporting changes necessary to satisfy the ticket.

The agent must not implement functionality explicitly assigned to later tickets.

If the implementation reveals a necessary architectural problem, prefer:

```text
smallest safe fix
```

over:

```text
large redesign
```

unless the ticket explicitly authorizes the redesign.

---

# 26. Definition of Done

A ticket is complete only when:

* Requested behavior exists.
* Existing functionality still works.
* Relevant tests exist.
* Tests pass.
* No known authorization bypass exists in the changed functionality.
* Database constraints are correct.
* Database migrations work.
* Frontend builds.
* No debug code remains.
* No secrets were introduced.
* The diff contains no unrelated changes.

---

# 27. Ticket Format

Every implementation ticket should use the following structure.

## Ticket ID

```text
PR-XX
```

## Title

Short description of the single responsibility.

## Objective

One or two sentences describing what this ticket accomplishes.

## Context

Why this functionality exists.

## Scope

Explicitly list what should be implemented.

## Out of Scope

Explicitly list what must not be implemented.

## Backend Requirements

List required Rails/API changes.

## Frontend Requirements

List required Vue changes.

## Database Requirements

List migrations, constraints, and indexes.

## Security / Authorization Requirements

List access-control expectations.

## Tests

List required automated tests.

## Acceptance Criteria

Specific observable conditions that indicate completion.

## Implementation Notes

Optional guidance that constrains the implementation without specifying every line of code.

---

# 28. Example Ticket

## Ticket ID

```text
PR-06
```

## Title

```text
Implement Daily Notes API
```

## Objective

Implement the backend API allowing calendar members to create, read, update, and delete one text note for a calendar day.

## Context

The application represents a calendar as a collection of day-based notes.

A calendar may contain only one note for each date.

## Scope

Implement:

* range note retrieval
* single-day note retrieval
* note creation
* note update
* note deletion
* authorization

## Out of Scope

Do not implement:

* Vue note editor
* autosave
* calendar rendering
* rich text
* multiple notes per day

## Backend Requirements

Implement endpoints equivalent to:

```text
GET    /api/calendars/:id/notes
GET    /api/calendars/:id/notes/:date
PUT    /api/calendars/:id/notes/:date
DELETE /api/calendars/:id/notes/:date
```

The date format is:

```text
YYYY-MM-DD
```

## Database Requirements

The database must enforce:

```text
UNIQUE(calendar_id, date)
```

The existing index should support:

```text
calendar_id + date
```

range queries.

## Security Requirements

Only calendar members may:

* read notes
* create notes
* edit notes
* delete notes

Users outside the calendar must receive an authorization failure.

## Tests

Test:

* member can retrieve notes
* member can create note
* member can update note
* member can delete note
* non-member cannot retrieve notes
* non-member cannot modify notes
* duplicate note for same calendar/date is impossible
* date range filtering works correctly

## Acceptance Criteria

Given a calendar member:

```text
When they request notes for September 2026
Then only notes belonging to that calendar and date range are returned.
```

Given a calendar member:

```text
When they save a note for 2026-09-16
Then a daily note exists for that calendar/date.
```

Given an existing note:

```text
When the member saves different text
Then the existing note is updated rather than a second note being created.
```

Given a non-member:

```text
When they request the calendar's notes
Then the request is rejected.
```

## Implementation Notes

Use a PostgreSQL `DATE`.

Do not convert calendar dates to timestamps.

Do not create one database query per day for range retrieval.

````

---

# 29. Definition of a Good AI-Generated PR

A good PR should be understandable by a developer who did not write it.

The reviewer should be able to answer:

```text
What problem does this solve?

Why are these files changed?

What business rule is being introduced?

How is it tested?

What is deliberately not included?
````

without reading hundreds of unrelated changes.

---

# 30. Product Boundary

The guiding principle for future development is:

> Keep the application closer to a digital sheet of calendar paper than to a traditional scheduling application.

Before adding a feature, determine whether it supports that core interaction.

Features involving:

```text
events
appointments
time slots
reminders
recurrence
external calendars
notifications
```

should be treated as separate product decisions rather than natural extensions of the existing model.

---

# 31. Priority Order

When implementation decisions conflict, use this priority order:

```text
1. Security
2. Data integrity
3. Correctness
4. Maintainability
5. Testability
6. User experience
7. Performance
8. Convenience
```

Do not sacrifice a higher-priority concern merely to simplify a lower-priority implementation.

---

# 32. Final Instruction to AI Agents

Do not attempt to build the entire product when given one ticket.

Complete the smallest correct piece of the system that satisfies the ticket.

Leave the repository in a better state than you found it, but do not broaden the scope unnecessarily.

When uncertain between two implementations, prefer the one that:

* is easier to understand
* uses fewer dependencies
* preserves existing architecture
* is easier to test
* has fewer implicit behaviors
* can be changed later without significant migration cost
