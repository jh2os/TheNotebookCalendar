# PR-03

## Title

Implement Magic Link Authentication

## Objective

Implement passwordless login, session creation, current-user access, and logout.

## Context

The application uses a conventional browser session rather than JWTs for authentication.

## Scope

- Add the magic-link request endpoint and email delivery.
- Generate secure, short-lived, single-use tokens.
- Verify tokens and create authenticated sessions.
- Add current-user and logout endpoints.
- Add authentication middleware/helpers.

## Out of Scope

- Calendar permissions and calendar UI.

## Backend Requirements

- Implement the complete request, delivery, verification, session, and logout flow.
- Return consistent responses without revealing whether an arbitrary email has an account.

## Frontend Requirements

- Provide only the integration needed to request and complete a magic-link login, if frontend wiring is in scope for the existing application.

## Database Requirements

- Persist token state securely with expiration and consumption tracking as needed.

## Security / Authorization Requirements

- Tokens must be cryptographically random, time-limited, single-use, and not stored as reusable plaintext credentials.
- Use a secure session cookie and consider CSRF protections for the Rails architecture.
- Logout must invalidate the session.

## Tests

- Test successful login, invalid/expired/reused tokens, session access, current-user responses, and logout.
- Test that authentication secrets are not exposed in responses or logs.

## Acceptance Criteria

- A user can request a link, receive it in development/test output, authenticate, access protected endpoints, and log out.
- Invalid, expired, and reused links fail safely.

## Implementation Notes

Development should provide a convenient way to inspect outgoing email without requiring an external provider.