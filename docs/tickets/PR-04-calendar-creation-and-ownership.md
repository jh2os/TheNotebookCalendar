# PR-04

## Title

Implement Calendar Creation and Ownership

## Objective

Allow authenticated users to create and manage calendars they own.

## Context

A user may own multiple calendars, and the creator is automatically a calendar member with the owner role.

## Scope

- Create, list, read, rename, and delete calendars.
- Automatically create owner membership when a calendar is created.
- Restrict calendar listings and details to calendars available to the current user.

## Out of Scope

- Membership administration UI and daily note endpoints.

## Backend Requirements

- Add resource-oriented calendar API endpoints.
- Enforce authentication and calendar-specific authorization in Rails.
- Handle associated memberships and notes correctly when deleting a calendar.

## Frontend Requirements

- Add only the integration required to create, select, and manage calendars if the existing frontend requires it.

## Database Requirements

- Preserve the owner foreign key and existing membership constraints.
- Ensure deletion behavior does not leave invalid associated records.

## Security / Authorization Requirements

- Users can only see calendars they belong to.
- Changing a calendar ID must not expose another user’s calendar.

## Tests

- Test multiple calendar creation, automatic owner membership, listing, rename, deletion, and cross-user access denial.

## Acceptance Criteria

- An authenticated user can create multiple calendars.
- The creator receives owner access automatically.
- Unauthorized calendar access is rejected at the API layer.
- Calendar deletion handles associated data correctly.

## Implementation Notes

Keep authorization in Rails even when the UI hides unavailable calendars.