# Build stage
FROM ruby:3.2 AS builder

# Install Node.js and Yarn for asset compilation
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    corepack enable && \
    rm -rf /var/lib/apt/lists/*

ENV APP_HOME=/webapp
ENV RAILS_ENV=production
WORKDIR $APP_HOME

# Install gems first (better layer caching)
COPY Gemfile Gemfile.lock* ./
RUN gem update --system && gem install bundler && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 && \
    rm -rf ~/.bundle/cache

# Copy app and install JS dependencies
COPY . .
RUN yarn install && \
    SECRET_KEY_BASE=dummy bundle exec rails assets:precompile && \
    rm -rf node_modules tmp/cache vendor/bundle/ruby/*/cache

# Runtime stage
FROM ruby:3.2-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 && \
    rm -rf /var/lib/apt/lists/*

ENV PORT=80
ENV APP_HOME=/webapp
ENV RAILS_ENV=production
WORKDIR $APP_HOME

# Copy gems and app from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder $APP_HOME $APP_HOME

CMD ["/bin/sh", "-c", "SECRET_KEY_BASE=$(bundle exec rails secret) bundle exec rails s -b 0.0.0.0 -p $PORT"]
