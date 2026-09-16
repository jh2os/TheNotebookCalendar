# PR-05

## Title

Implement Calendar Membership Management

## Objective

Allow calendar owners to control which existing users can access a calendar.

## Context

Calendars support the `owner` and `member` roles. Membership changes must be enforced by the backend.

## Scope

- List members.
- Add an existing user by email.
- Remove a member.
- Implement owner/member role handling and authorization.

## Out of Scope

- Invitation emails, pending invitations, and roles beyond owner/member.

## Backend Requirements

- Add member list, add, and remove endpoints.
- Return clear errors when the target email does not belong to an existing user.

## Frontend Requirements

- Add the owner-facing member-management interface only if frontend work is part of this ticket’s implementation surface.

## Database Requirements

- Preserve unique `(calendar_id, user_id)` membership integrity.

## Security / Authorization Requirements

- Only owners may add or remove members.
- Members cannot modify membership.
- Owners cannot remove themselves or the owner membership through normal removal.
- Removal immediately prevents access.

## Tests

- Test owner listing, adding, and removing members.
- Test member denial, owner protection, duplicate membership handling, and unauthorized calendar access.

## Acceptance Criteria

- An owner can add an existing user and remove another member.
- A normal member cannot administer membership.
- The owner cannot accidentally remove their own ownership.
- Unauthorized operations return appropriate HTTP errors.

## Implementation Notes

Most of this ticket should be backend authorization rather than UI behavior.