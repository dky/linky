# This docker file sets up the rails app container
#
# https://docs.docker.com/reference/builder/

FROM ruby:3.2

# Install Node.js and Yarn for asset compilation
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Add env variables
ENV PORT=80
ENV APP_HOME=/webapp
ENV RAILS_ENV=production

# switch to the application directory for exec commands
WORKDIR $APP_HOME

# Add the app
ADD . $APP_HOME

RUN gem update --system && gem install bundler

RUN bundle install

# Install JS dependencies and build assets
RUN yarn install
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# Run the app
CMD ["/bin/sh", "-c", "SECRET_KEY_BASE=$(bundle exec rails secret) bundle exec rails s -b 0.0.0.0 -p $PORT"]
