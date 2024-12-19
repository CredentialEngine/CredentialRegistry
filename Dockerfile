FROM ruby:3.2.2

ARG ENCRYPTED_PRIVATE_KEY_SECRET

ENV APP_PATH /app/
ENV LANGUAGE en_US:en  
ENV LANG C.UTF-8  
ENV LC_ALL C.UTF-8
ENV BUNDLE_PATH=/app/vendor/bundle
ENV ENCRYPTED_PRIVATE_KEY_SECRET=$ENCRYPTED_PRIVATE_KEY_SECRET

WORKDIR $APP_PATH

RUN apt-get update && \
    apt-get install -y \
    lsb-release \
    curl && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
RUN curl -Ss https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list \
    && apt-get update -qqy \
    && apt-get install -y \
    --no-install-recommends \
    postgresql-client-16 && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
COPY Gemfile Gemfile.lock ./

RUN gem install bundler  && bundle config set deployment true && DOCKER_ENV=true RACK_ENV=production bundle install
COPY . $APP_PATH

USER registry
RUN bin/install_swagger

COPY docker-entrypoint.sh /usr/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9292
