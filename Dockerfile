# syntax=docker/dockerfile:1
# check=skip=true

ARG RUBY_VERSION=3.4.10
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base packages + Node.js/npm for runtime asset generation
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client nodejs npm && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Allow changing environment at runtime (defaulting to production fallback)
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY vendor/* ./vendor/
COPY Gemfile Gemfile.lock ./

# Install ALL gems (including development/test for your docker-compose environment)
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

COPY package.json package-lock.json ./
RUN npm install

COPY . .

RUN APP_HOST=example.test SECRET_KEY_BASE_DUMMY=1 SMTP_PASSWORD=dummy bundle exec bootsnap precompile -j 1 app/ lib/
RUN APP_HOST=example.test SECRET_KEY_BASE_DUMMY=1 SMTP_PASSWORD=dummy ./bin/rails assets:precompile

FROM base AS final

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
    
# Fix file system permissions for the runtime user workspace
RUN mkdir -p tmp/pids logs node_modules && chown -R rails:rails /rails

USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
#CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
CMD ["bin/dev"]