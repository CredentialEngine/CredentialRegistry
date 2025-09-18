#############################
# Build stage (UBI 10 minimal)
#############################
FROM registry.access.redhat.com/ubi10/ubi-minimal AS builder

ARG PLAT=x86_64
ARG RUBY_VERSION=3.4.3
ENV APP_PATH=/app/
ENV LANGUAGE=en_US:en
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV BUNDLE_PATH=/app/vendor/bundle
ENV PLAT=$PLAT
ENV RUBY_VERSION=$RUBY_VERSION
ENV PATH="/usr/local/bin:$PATH"

WORKDIR $APP_PATH

# Keep local RPMs available in the build context (not installed on UBI 10)
#COPY rpms/ /tmp/rpms/

# Install build tools and runtime libs in builder
RUN set -eux; \
    microdnf -y update; \
    microdnf -y install --setopt=install_weak_deps=0 --setopt=tsflags=nodocs \
    git gcc-c++ make which tar bzip2 \
    curl gnupg2 \
    autoconf automake bison patch \
    openssl openssl-devel \
    zlib zlib-devel \
    libyaml libyaml-devel \
    readline-devel \
    libffi libffi-devel \
    ncurses ncurses-devel \
    findutils diffutils procps-ng \
    ca-certificates \
    libpq libpq-devel \
    sqlite sqlite-devel \
    libxml2 libxml2-devel \
    libxslt libxslt-devel \
    pkgconf-pkg-config \
    && microdnf clean all


# Build and install Ruby from source (no RVM)
RUN set -eux; \
    curl -fsSL https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz -o /tmp/ruby.tar.gz; \
    mkdir -p /tmp/ruby-src; tar -xzf /tmp/ruby.tar.gz -C /tmp/ruby-src --strip-components=1; \
    cd /tmp/ruby-src; \
    ./configure --disable-install-doc --with-openssl-dir=/usr; \
    make -j"$(nproc)" && make install; \
    rm -rf /tmp/ruby-src /tmp/ruby.tar.gz; \
    gem update --system || true

COPY Gemfile Gemfile.lock .ruby-version $APP_PATH
RUN gem install bundler && \
    bundle config set deployment true && \
    DOCKER_ENV=true RACK_ENV=production bundle install

# Copy application sources
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

COPY docker-entrypoint.sh /tmp/docker-entrypoint.sh

# Collect runtime artifacts to a staging dir
RUN mkdir -p /runtime/usr/local /runtime/etc /runtime/usr/bin /runtime/usr/lib64 && \
    # Ruby runtime from /usr/local
    mkdir -p /runtime/usr/local/bin /runtime/usr/local/lib && \
    cp -a /usr/local/bin/ruby /runtime/usr/local/bin/ && \
    cp -a /usr/local/bin/gem /usr/local/bin/rake /usr/local/bin/bundle /usr/local/bin/bundler /runtime/usr/local/bin/ 2>/dev/null || true && \
    cp -a /usr/local/lib/ruby /runtime/usr/local/lib/ && \
    cp -a /etc/pki /runtime/etc/ && \
    cp -a /etc/ssl /runtime/etc/ || true && \
    cp -a /usr/bin/openssl /runtime/usr/bin/ && \
    # Copy commonly required runtime shared libraries
    for lib in \
    /usr/lib64/libpq.so.* \
    /usr/lib64/libssl.so.* \
    /usr/lib64/libcrypto.so.* \
    /usr/lib64/libyaml-0.so.* \
    /usr/lib64/libreadline.so.* \
    /usr/lib64/libncursesw.so.* \
    /usr/lib64/libz.so.* \
    /usr/lib64/libzstd.so.* \
    /usr/lib64/libgmp.so.* \
    /usr/lib64/libffi.so.* \
    ; do cp -a $lib /runtime/usr/lib64/ 2>/dev/null || true; done && \
    # App
    cp -a $APP_PATH /runtime/app && \
    chmod +x /tmp/docker-entrypoint.sh && cp /tmp/docker-entrypoint.sh /runtime/usr/bin/docker-entrypoint.sh

#############################
# Runtime stage (UBI 10 micro)
#############################
FROM registry.access.redhat.com/ubi10/ubi-micro

ENV APP_PATH=/app/
ARG RUBY_VERSION=3.4.3
ENV PATH="/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global/bin:/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/bin:$PATH"
ENV GEM_HOME='/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global'
ENV GEM_PATH='/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global'
ENV MY_RUBY_HOME='/usr/local/rvm/rubies/ruby-${RUBY_VERSION}'
ENV IRBRC='/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/.irbrc'

WORKDIR $APP_PATH

# Copy runtime files from builder
COPY --from=builder /runtime/ /

# Create runtime user
RUN useradd -m registry && chown -R registry:registry /app
USER registry

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

EXPOSE 9292
