# PR-08

## Title

Implement the Day Note Editor

## Objective

Connect the selected calendar day to the daily notes API with explicit save behavior.

## Context

Selecting a day should expose one simple text editor for that day’s existing or new note.

## Scope

- Add the note editor component.
- Load the selected day’s note.
- Save new and changed notes.
- Delete or clear notes.
- Show saved/unsaved, loading, and error states.
- Refresh the calendar note indicator after changes.

## Out of Scope

- Autosave, rich text editing, and weekly view.

## Backend Requirements

- Use the existing daily notes API and its authorization rules.

## Frontend Requirements

- Keep the editor independent of the month calendar component where practical.
- Preserve `YYYY-MM-DD` values without unnecessary JavaScript `Date` conversion.

## Database Requirements

- Do not create an empty persistent record when a note is cleared.

## Security / Authorization Requirements

- Handle authentication, authorization, validation, network, and server errors visibly.

## Tests

- Test loading an existing note, creating, updating, clearing, saved/unsaved state, loading state, errors, and calendar indicator updates.

## Acceptance Criteria

- Selecting a day loads its note.
- Saving creates or updates the note.
- Clearing removes it and updates the day indicator.
- Empty days show an empty editor.

## Implementation Notes

Use explicit save behavior; do not introduce autosave accidentally.