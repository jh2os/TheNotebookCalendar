# The Notebook Calendar

The Notebook Calendar is a shared, day-based notebook. Each calendar has at most one freeform text note for each date.

## Requirements

- Ruby version from `.ruby-version`
- Node.js 22.12 or newer, with npm
- PostgreSQL

## Local setup

Install dependencies and prepare the development database:

```sh
bin/setup
```

Create a local environment file when you need to override defaults:

```sh
cp .env.example .env
```

`.env` is ignored by Git. Never commit `.env`, credentials, API keys, passwords, or magic-link tokens.

Run Rails and Vite together:

```sh
bin/dev
```

The application runs at `http://localhost:3000`. The health endpoint is `GET /up`.

## Database

Development and test use PostgreSQL databases named `the_notebook_calendar_development` and `the_notebook_calendar_test` by default. Override the connection with the normal Rails database environment variables, such as `DATABASE_URL`.

Prepare or migrate the current environment with:

```sh
bin/rails db:prepare
bin/rails db:migrate
```

Production uses four PostgreSQL databases: primary, cache, queue, and cable. Set `THE_NOTEBOOK_CALENDAR_DATABASE_PASSWORD` before booting. Run migrations from the application image or release environment after the database credentials are available:

```sh
RAILS_ENV=production bin/rails db:prepare
```

The production Docker entrypoint runs `db:prepare` when starting the Rails server. Review migration output during deployment and take database backups before schema changes.

## Environment variables

See `.env.example` for the complete list. Production requires:

- `RAILS_MASTER_KEY` to decrypt Rails credentials
- `SECRET_KEY_BASE` for signed and encrypted cookies
- `APP_HOST` without a protocol, plus `APP_PROTOCOL`
- `THE_NOTEBOOK_CALENDAR_DATABASE_PASSWORD`
- `POSTMARK_SERVER_TOKEN` for Postmark SMTP authentication, or `SMTP_PASSWORD` for another SMTP provider
- `MAILER_FROM`

Production SSL and host protection are enabled by default. Set `RAILS_ASSUME_SSL` and `RAILS_FORCE_SSL` to `false` only when an external proxy is deliberately responsible for equivalent TLS behavior.

## Authentication and authorization

Authentication is passwordless. A user submits an email address, receives a short-lived single-use magic link, and the browser receives a server-backed session after verification. The application does not log or return authentication tokens.

### Postmark email

Create a Postmark server, verify the sender signature used by `MAILER_FROM`, and store the server token as `POSTMARK_SERVER_TOKEN`. The production SMTP defaults are Postmark's SMTP endpoint, port 587, and username `postmark`. The server token is used as the SMTP password. Keep the token in `.kamal/secrets` or another secret manager; never commit it or print it in logs.

Calendar access is membership-based. Owners can manage members; members can read and edit calendar notes; users outside a calendar cannot access its calendars, members, or notes. The backend enforces these rules independently of the Vue UI.

## API conventions

Protected API requests use the browser session cookie. Dates are date-only values in `YYYY-MM-DD` format.

Common endpoints include:

```text
POST   /api/auth/magic_links
GET    /api/auth/magic_links/:token
GET    /api/auth/session
DELETE /api/auth/session

GET    /api/calendars
POST   /api/calendars
GET    /api/calendars/:id/notes?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
PUT    /api/calendars/:id/notes/:date
DELETE /api/calendars/:id/notes/:date
GET    /api/calendars/:id/members
POST   /api/calendars/:id/members
DELETE /api/calendars/:id/members/:user_id
```

The database enforces unique email addresses, calendar memberships, and one daily note per calendar/date.

## Tests and checks

Run the backend and browser suites:

```sh
bin/rails test
bin/rails db:test:prepare test:system
```

Run static checks and the production frontend build:

```sh
bin/rubocop -f github
npm run build
```

Run all repository checks together:

```sh
bin/rails db:test:prepare test test:system
bin/rubocop -f github
npm run build
```

## Health checks and logging

Use `/up` for load balancers and uptime monitoring:

```sh
curl --fail --silent --show-error https://calendar.example.com/up
```

Production logs are tagged and written to standard output for the container runtime. Keep `RAILS_LOG_LEVEL` at `info` or higher in production. Do not enable debug logging when authentication or personal data could be exposed.

## Docker and deployment

Build the production image:

```sh
docker build -t the_notebook_calendar .
```

Run it with runtime secrets and environment variables; do not copy `.env` into the image:

```sh
docker run --env-file .env -p 3000:80 the_notebook_calendar
```

Kamal deployment configuration lives in `config/deploy.yml`. Set the real server, registry, host, database password, Rails master key, Postmark server token, and mail sender in your deployment environment or `.kamal/secrets` before running:

```sh
bin/kamal deploy
```

The deployment image runs as a non-root user, serves the prebuilt Vite assets, and uses the Rails health endpoint for readiness checks. Confirm `/up`, magic-link delivery, database migrations, and login before directing traffic to a new release.
