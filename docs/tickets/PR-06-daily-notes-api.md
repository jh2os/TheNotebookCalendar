# PR-06

## Title

Implement the Daily Notes API

## Objective

Implement the API for reading and writing one freeform note per calendar day.

## Context

Daily notes are identified by `(calendar_id, date)` and use the ISO `YYYY-MM-DD` representation.

## Scope

- Retrieve notes for a date range.
- Retrieve a single day’s note.
- Create or update a day’s note.
- Delete a day’s note.
- Enforce calendar membership authorization.

## Out of Scope

- Vue note editor, autosave, calendar rendering, rich text, and multiple notes per day.

## Backend Requirements

- Implement predictable endpoints for range retrieval, single-day retrieval, upsert, and deletion.
- Validate dates and ranges.
- Treat empty note content as deletion or no stored record.

## Frontend Requirements

- None beyond the API contract needed by later calendar tickets.

## Database Requirements

- Use PostgreSQL `DATE` values and the `(calendar_id, date)` unique constraint/index.

## Security / Authorization Requirements

- Only calendar members may read, create, update, or delete notes.

## Tests

- Test range filtering, single-day retrieval, create, update, delete, empty notes, duplicate prevention, and non-member denial.

## Acceptance Criteria

- A calendar cannot contain two notes for one date.
- Range responses contain only the requested calendar and date range.
- Unauthorized users cannot read or modify notes.

## Implementation Notes

Monthly and weekly queries should use a small number of database queries and the composite calendar/date index.