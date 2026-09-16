# PR-09

## Title

Implement the Weekly Calendar View

## Objective

Add an alternative seven-day view using the existing calendar, notes, and editor abstractions.

## Context

Month and week views should show the same day-based notes and differ only in visible date range.

## Scope

- Render seven consecutive days.
- Navigate to the previous and next week and return to the current week.
- Support day selection and existing note indicators.
- Allow switching between month and week views.
- Reuse the note editor.

## Out of Scope

- New note behavior, theme support, and unrelated calendar redesign.

## Backend Requirements

- Reuse the existing notes range API.

## Frontend Requirements

- Reuse calendar and note components/abstractions rather than creating a parallel implementation.
- Preserve date-only semantics and load one weekly range.

## Database Requirements

- None beyond existing calendar/date indexes.

## Security / Authorization Requirements

- Continue relying on backend authorization for calendar and notes.

## Tests

- Test switching views, seven-day rendering, week navigation, day selection, shared indicators, editor reuse, and one range request per week.

## Acceptance Criteria

- Users can switch between month and week.
- Both views display the same underlying notes.
- Editing in one view is reflected in the other after state update or refresh.
- Weekly loading does not make seven day requests.

## Implementation Notes

Consume the existing calendar and note abstractions instead of duplicating them.