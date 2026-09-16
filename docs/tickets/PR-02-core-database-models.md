# PR-02

## Title

Implement Core Database Models

## Objective

Create the persistent domain model for users, calendars, memberships, and daily notes.

## Context

The product is a shared collection of one freeform note per calendar day.

## Scope

- Create `users`, `calendars`, `calendar_memberships`, and `daily_notes`.
- Add Active Record associations, validations, foreign keys, constraints, and required indexes.
- Add model tests.

## Out of Scope

- Authentication, controllers, Vue UI, and calendar creation workflows.

## Backend Requirements

- Model users, calendars, memberships, and daily notes with the required associations and validations.

## Frontend Requirements

- None.

## Database Requirements

- Unique user email.
- Unique `(calendar_id, user_id)` membership.
- Unique `(calendar_id, date)` daily note.
- PostgreSQL `DATE` for the note date.
- Foreign keys and indexes, including `calendars.created_by_id` and `(calendar_id, date)`.

## Security / Authorization Requirements

- No endpoint authorization is required yet; preserve ownership and membership fields for later authorization.

## Tests

- Test associations and important validations.
- Test database-enforced uniqueness and foreign-key behavior where practical.
- Test that daily notes use date-only values.

## Acceptance Criteria

- An empty database migrates successfully.
- Required relationships and constraints are present.
- Duplicate emails, memberships, and notes for the same calendar/date are rejected.

## Implementation Notes

Do not rely on model validations alone for uniqueness.