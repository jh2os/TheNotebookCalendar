# PR-13

## Title

Harden Authorization, Security, and Integration Behavior

## Objective

Perform a dedicated security and cross-feature verification pass with adversarial automated tests.

## Context

Security rules must remain enforced even when requests bypass the UI or manipulate resource identifiers.

## Scope

- Add tests for unauthenticated requests and unauthorized calendar, note, and membership access.
- Test expired and reused magic links, logout, cross-calendar leakage, duplicate memberships, duplicate notes, and calendar deletion.
- Fix security defects discovered by these tests.

## Out of Scope

- New user-facing features or unrelated refactoring.

## Backend Requirements

- Ensure every protected operation checks authentication and resource-specific authorization.
- Ensure error responses do not leak sensitive data.

## Frontend Requirements

- None beyond addressing a concrete integration defect exposed by the tests.

## Database Requirements

- Verify uniqueness, foreign-key, and deletion behavior under adversarial requests.

## Security / Authorization Requirements

- A user must not access another calendar’s metadata, members, or notes by changing IDs or dates.
- Expired/reused magic links and logged-out sessions must not authenticate.

## Tests

- Add the full adversarial test matrix described in scope.
- Include cross-calendar and cross-user request tests.

## Acceptance Criteria

- All protected operations reject unauthenticated or unauthorized requests.
- No cross-calendar data leakage is possible through API parameters.
- Duplicate memberships and notes remain impossible.

## Implementation Notes

Prioritize behavior-level security tests over UI-only checks.