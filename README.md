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

To load local secrets and environment variables, copy the example file and fill in the values:

```sh
cp .env.example .env
```

The `.env` file is ignored by Git. For production Docker runs, pass the file at runtime with `docker run --env-file .env ...`; do not copy it into the image.

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
