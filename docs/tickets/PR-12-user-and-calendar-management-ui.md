# PR-12

## Title

Implement User and Calendar Management UI

## Objective

Complete the user-facing management screens for calendars, memberships, and logout.

## Context

The core calendar and note workflows are usable, but users need clear screens for managing calendars and shared access.

## Scope

- Add calendar list, creation, rename, and deletion confirmation.
- Add member list, add-member, and remove-member controls.
- Show owner-only controls.
- Add logout.

## Out of Scope

- Invitation emails, pending invitations, new role types, and changes to backend authorization rules.

## Backend Requirements

- Consume the existing calendar, membership, session, and current-user APIs.
- Surface validation and authorization failures clearly.

## Frontend Requirements

- Complete the typical login-to-calendar-to-note workflow.
- Hide owner-only controls for members while still relying on backend enforcement.
- Include loading and error states for management operations.

## Database Requirements

- None beyond existing models and constraints.

## Security / Authorization Requirements

- The UI must not imply access beyond what the backend grants.
- Logout must invalidate the authenticated session.

## Tests

- Test listing, creating, selecting, renaming, and deleting calendars.
- Test owner member management, member visibility, owner-only controls, and logout.

## Acceptance Criteria

- A user can log in, see calendars, create/select one, write a note, switch views, and log out.
- An owner can add and remove members through the UI.
- A member cannot administer membership.

## Implementation Notes

Keep management screens separate from calendar rendering and note editing responsibilities.