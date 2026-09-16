# The Notebook Calendar

## Requirements

- Ruby version in `.ruby-version`
- Node.js 22.12+ with npm
- PostgreSQL

## Setup

```sh
bin/setup
```

The setup command installs Ruby and JavaScript dependencies and prepares the development database.

## Development

Run Rails and Vite together with:

```sh
bin/dev
```

The application is available at `http://localhost:3000`. The `/up` endpoint is the health check used by the application and deployment tooling.

## Tests and checks

```sh
bin/rails test
bin/rubocop
npm run build
```

The frontend entrypoint mounts Vue at the root page and checks the Rails health endpoint to verify the frontend/API boundary.
