# Use Red Hat Universal Base Image 8
FROM registry.access.redhat.com/ubi8/ubi:latest

ARG ENCRYPTED_PRIVATE_KEY_SECRET
ARG PLAT=x86_64
ARG RUBY_VERSION=3.3.5
ENV APP_PATH /app/
ENV LANGUAGE en_US:en
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV BUNDLE_PATH=/app/vendor/bundle
ENV ENCRYPTED_PRIVATE_KEY_SECRET=$ENCRYPTED_PRIVATE_KEY_SECRET
ENV SECRET_KEY_BASE=${ENCRYPTED_PRIVATE_KEY_SECRET}
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
RUN curl ${RPMFIND_REPO}/BaseOS/$PLAT/os/Packages/${READLINE_PACK_NAME}.el8.$PLAT.rpm -o readline-devel.rpm && \
    curl ${RPMFIND_REPO}/AppStream/$PLAT/os/Packages/${BISON_PACK_NAME}.el8.$PLAT.rpm -o bison.rpm && \
    dnf -y install libpq.${PLAT} libpq-devel.${PLAT} dnf-plugins-core git gcc-c++ make openssl-devel diffutils procps-ng zlib-devel which tar bzip2 libyaml-devel readline-devel.rpm bison.rpm

# Install the PostgreSQL repository
RUN dnf -y install ${PG_REPO}/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Import the appropriate PG repo GPG Key based on PLAT
RUN if [ "$PLAT" = "aarch64" ]; then \
    curl -sL ${PG_REPO}/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL -o /etc/pki/rpm-gpg/PGDG-RPM-GPG-KEY-RHEL; \
    else \
    curl -sL ${PG_REPO}/keys/PGDG-RPM-GPG-KEY-RHEL -o /etc/pki/rpm-gpg/PGDG-RPM-GPG-KEY-RHEL; \
    fi

# Install PostgreSQL
RUN dnf -y install postgresql16 &&  dnf clean all

# Install Ruby RVM
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    /usr/local/rvm/bin/rvm install ${RUBY_VERSION}

COPY Gemfile Gemfile.lock .ruby-version ./

RUN gem install bundler  && bundle config set deployment true && DOCKER_ENV=true RACK_ENV=production bundle install
COPY . $APP_PATH

RUN useradd -m registry
RUN chown -R registry:registry /app
USER registry

COPY docker-entrypoint.sh /usr/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9292
