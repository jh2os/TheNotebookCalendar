# PR-14

## Title

Verify End-to-End User Flows and Apply Final Polish

## Objective

Verify that the application works as a cohesive product through browser-level workflows.

## Context

Individual components and APIs can pass tests while their integrated authentication, calendar, notes, sharing, and theme flows still fail.

## Scope

- Add end-to-end coverage for new users, existing users, sharing, and security.
- Fix integration defects and apply only the polish required for these flows.

## Out of Scope

- New product capabilities, deployment changes, and broad redesign.

## Backend Requirements

- Support the existing browser workflows without development-only shortcuts.

## Frontend Requirements

- Verify login, calendar creation, month/week navigation, note persistence, theme changes, member sharing, and logout in the browser.

## Database Requirements

- Verify persisted notes and memberships survive the tested workflows correctly.

## Security / Authorization Requirements

- Verify members cannot administer membership and non-members cannot access calendars.

## Tests

- New user: request magic link, log in, create calendar, write note, refresh, and verify persistence.
- Existing user: select calendar, navigate month/week, edit note, change theme, and log out.
- Sharing: owner adds member, member logs in and edits a note, owner sees the change.
- Security: member membership administration and non-member calendar access are denied.

## Acceptance Criteria

- All core workflows work from the browser without development-only shortcuts.
- End-to-end tests pass reliably.

## Implementation Notes

Keep fixes narrowly tied to failures found in the end-to-end flows.