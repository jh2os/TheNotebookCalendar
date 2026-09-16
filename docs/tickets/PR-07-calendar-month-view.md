# PR-07

## Title

Implement the Calendar Month View

## Objective

Build the first usable calendar interface as a monthly view.

## Context

The month view is the default calendar experience and consumes the daily notes range API.

## Scope

- Display the current month by default.
- Navigate to the previous and next month and return to the current month.
- Render a seven-day week layout.
- Highlight today, select days, show note indicators, and select a calendar.

## Out of Scope

- Editing note text, weekly view, and dark mode.

## Backend Requirements

- Consume the existing calendar and notes endpoints without adding unrelated API behavior.

## Frontend Requirements

- Build the monthly view from date-only values.
- Keep day selection available on desktop and touch devices.
- Load notes with one date-range request for the visible month.

## Database Requirements

- None beyond the existing model and notes API.

## Security / Authorization Requirements

- Rely on backend authorization for calendar and note access.

## Tests

- Test default month rendering, navigation, current-day highlighting, day selection, note indicators, and range loading behavior.

## Acceptance Criteria

- A user can select a calendar and navigate months.
- Days with notes are visually distinguishable.
- Selecting a day exposes the selected date to the rest of the application.
- The view does not issue one request per day.

## Implementation Notes

Focus on correct rendering and date semantics; note editing belongs to PR-08.