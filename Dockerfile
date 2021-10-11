FROM ruby:2.7.3

ENV APP_PATH /app/

ENV LANGUAGE en_US:en  
ENV LANG C.UTF-8  
ENV LC_ALL C.UTF-8

WORKDIR $APP_PATH

RUN apt-get update -y && apt-get install -y --no-install-recommends postgresql-client 

COPY Gemfile Gemfile.lock ./

RUN gem install bundler
RUN bundle install

ADD . $APP_PATH

RUN bin/install_swagger

COPY docker-entrypoint.sh /usr/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9292