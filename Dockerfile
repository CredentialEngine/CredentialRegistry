# Use Red Hat Universal Base Image 8
FROM registry.access.redhat.com/ubi8:8.10-1752733233

ARG PLAT=x86_64
ARG RUBY_VERSION=3.3.5
ENV APP_PATH=/app/
ENV LANGUAGE=en_US:en
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV BUNDLE_PATH=/app/vendor/bundle
ENV PLAT=$PLAT
ENV READLINE_PACK_NAME=readline-devel-7.0-10
ENV BISON_PACK_NAME=bison-3.0.4-10
ENV RUBY_VERSION=$RUBY_VERSION
ENV PG_REPO=https://download.postgresql.org/pub/repos/yum
ENV RPMFIND_REPO=https://rpmfind.net/linux/almalinux/8.10
ENV PATH="/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global/bin:/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/bin:$PATH"
ENV GEM_HOME='/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global'
ENV GEM_PATH='/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global'
ENV MY_RUBY_HOME='/usr/local/rvm/rubies/ruby-${RUBY_VERSION}'
ENV IRBRC='/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/.irbrc'

WORKDIR $APP_PATH

# Install necessary tools and deps
# Import the appropriate PG repo GPG Key based on PLAT
RUN if [ "$PLAT" = "aarch64" ]; then \
    curl -sL ${PG_REPO}/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL -o /etc/pki/rpm-gpg/PGDG-RPM-GPG-KEY-RHEL; \
    else \
    curl -sL ${PG_REPO}/keys/PGDG-RPM-GPG-KEY-RHEL -o /etc/pki/rpm-gpg/PGDG-RPM-GPG-KEY-RHEL; \
    fi

COPY readline-devel.rpm bison.rpm $APP_PATH
RUN dnf -y install libpq.${PLAT} libpq-devel.${PLAT} dnf-plugins-core git gcc-c++ make openssl-devel \
    diffutils procps-ng zlib-devel which tar bzip2 libyaml-devel readline-devel.rpm bison.rpm \
    # Install the PostgreSQL repository
    ${PG_REPO}/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    # Install PostgreSQL
    #postgresql16 &&  dnf clean all \
    # Install Ruby RVM
    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    /usr/local/rvm/bin/rvm install ${RUBY_VERSION} 

## set to a dummy value which will be overriden in docker-entrypoint.sh file
ENV SECRET_KEY_BASE=dummy-value

COPY Gemfile Gemfile.lock .ruby-version $APP_PATH
RUN gem install bundler  && bundle config set deployment true && DOCKER_ENV=true RACK_ENV=production bundle install
COPY app/       $APP_PATH/app
COPY bin/       $APP_PATH/bin
COPY config/    $APP_PATH/config
COPY db/        $APP_PATH/db
COPY fixtures/  $APP_PATH/fixtures
COPY lib/       $APP_PATH/lib
COPY log/       $APP_PATH/log
COPY public/    $APP_PATH/public
COPY config.ru  $APP_PATH
COPY Rakefile   $APP_PATH

COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh && useradd -m registry && chown -R registry:registry /app
USER registry


ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9292
