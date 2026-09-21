# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.4.10
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Base runtime libraries needed in both dev and prod
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV BUNDLE_PATH="/usr/local/bundle" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# ==============================================================================
# 1. DEVELOPMENT TARGET (Used by docker-compose for local development)
# ==============================================================================
FROM base AS development

# Development needs Node, NPM, git, and compilers for gem building & Vite hot-reloading
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips libyaml-dev pkg-config nodejs npm && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="development"

COPY Gemfile Gemfile.lock package.json package-lock.json ./
RUN bundle install && npm install

COPY . .

EXPOSE 3000 3036
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

# ==============================================================================
# 2. BUILD STAGE (Compiles production assets & gems)
# ==============================================================================
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips libyaml-dev pkg-config nodejs npm && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_WITHOUT="development:test"

COPY vendor/* ./vendor/
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Precompile Bootsnap code & Vite/Rails production assets
RUN APP_HOST=example.test SECRET_KEY_BASE_DUMMY=1 bundle exec bootsnap precompile -j 1 app/ lib/
RUN APP_HOST=example.test SECRET_KEY_BASE_DUMMY=1 \
    RAILS_ENV=production SMTP_PASSWORD='dummy' \
./bin/rails assets:precompile

# Clean up build artifacts before copying to runtime image
RUN rm -rf node_modules tmp/cache

# ==============================================================================
# 3. PRODUCTION TARGET (Deployed to AWS ECS)
# ==============================================================================
FROM base AS final

ENV RAILS_ENV="production"

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

RUN mkdir -p tmp/pids log storage && chown -R rails:rails /rails

USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]