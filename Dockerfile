FROM ruby:2.7.3

ENV APP_PATH /app/

ENV LANGUAGE en_US:en  
ENV LANG C.UTF-8  
ENV LC_ALL C.UTF-8

WORKDIR $APP_PATH

RUN apt-get update && apt-get install -y lsb-release

RUN curl -Ss https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list \
    && apt-get update -qqy \
    && apt-get install -y --no-install-recommends postgresql-client-13

COPY Gemfile Gemfile.lock ./

RUN gem install bundler
RUN bundle install

ADD . $APP_PATH

RUN bin/install_swagger

COPY docker-entrypoint.sh /usr/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9292