# PR-01

## Title

Bootstrap the Application

## Objective

Create the basic Rails and Vue application structure and development workflow without implementing product functionality.

## Context

This establishes the application boundary, local workflow, and quality checks for later tickets.

## Scope

- Create the Rails application and PostgreSQL configuration.
- Configure Vue and the Rails API/frontend boundary.
- Establish development commands, automated tests, linting, formatting, CI, and environment conventions.
- Add a simple health endpoint.

## Out of Scope

- Users, authentication, calendars, notes, and product styling beyond bootstrapping.

## Backend Requirements

- Rails application can connect to PostgreSQL.
- Add a health endpoint and the initial API boundary.

## Frontend Requirements

- Vue application loads and can make a request to Rails.

## Database Requirements

- Configure PostgreSQL; do not add product tables.

## Security / Authorization Requirements

- No authentication or authorization functionality is required yet.

## Tests

- Verify the Rails application boots, the health endpoint responds, the Vue application loads, and the configured test/lint commands execute.

## Acceptance Criteria

- Application starts locally.
- Rails connects to PostgreSQL.
- Vue loads and communicates with Rails.
- Tests and CI checks run successfully.

## Implementation Notes

Keep this ticket architectural. Do not allow scaffolding to grow into product code.