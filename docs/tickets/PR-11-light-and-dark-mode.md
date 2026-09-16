# PR-11

## Title

Implement Light and Dark Mode

## Objective

Add application-wide theme support with a user-controlled light/dark switch.

## Context

Theme state should be consistent across the calendar, editor, navigation, and management surfaces.

## Scope

- Add light and dark themes.
- Add a theme switcher.
- Persist the user preference locally.
- Respect system preference initially where appropriate.

## Out of Scope

- Changes to calendar behavior, authentication, or authorization.

## Backend Requirements

- None.

## Frontend Requirements

- Centralize theme variables/tokens rather than scattering theme logic across components.
- Keep all controls, calendar content, and editor content legible in both themes.

## Database Requirements

- None; local preference persistence is sufficient.

## Security / Authorization Requirements

- None beyond preserving existing behavior.

## Tests

- Test switching themes, persisted preference after reload, system preference initialization, and accessible contrast for major controls/content.

## Acceptance Criteria

- Users can switch themes without a reload.
- Preference survives page reload.
- Calendar and editor remain legible with accessible control contrast.

## Implementation Notes

Prefer shared CSS variables/design tokens over component-specific theme decisions.