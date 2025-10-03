# Build stage (UBI 10 minimal)
FROM registry.access.redhat.com/ubi10/ubi-minimal:10.0-1758185635 AS builder

ARG PLAT=x86_64
ARG RUBY_VERSION=3.4.6
ENV APP_PATH=/app/
ENV LANGUAGE=en_US:en
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV BUNDLE_PATH=/app/vendor/bundle
ENV PLAT=$PLAT
ENV RUBY_VERSION=$RUBY_VERSION
ENV PATH="/usr/local/bin:$PATH"

WORKDIR $APP_PATH

# Install build tools and runtime libs in builder
RUN set -eux; \
    microdnf -y update; \
    microdnf -y install --setopt=install_weak_deps=0 --setopt=tsflags=nodocs \
    git gcc-c++ make which tar bzip2 \
    curl gnupg2 \
    autoconf automake patch \
    unzip \
    m4 \
    openssl openssl-devel \
    zlib zlib-devel \
    libyaml libyaml-devel \
    libffi libffi-devel \
    ncurses ncurses-devel \
    findutils diffutils procps-ng \
    ca-certificates \
    libpq libpq-devel \
    postgresql \
    krb5-libs \
    openldap \
    cyrus-sasl-lib \
    keyutils-libs \
    libevent \
    lz4-libs \
    tzdata \
    sqlite sqlite-devel \
    libxml2 libxml2-devel \
    libxslt libxslt-devel \
    pkgconf-pkg-config \
    && microdnf clean all

# Install local RPMs shipped in repo (EL10 builds)
COPY rpms/ /tmp/rpms/
RUN if ls /tmp/rpms/*.rpm >/dev/null 2>&1; then rpm -Uvh --nosignature /tmp/rpms/*.rpm; fi

# Build and install Ruby from source (no RVM)
RUN set -eux; \
    curl -fsSL https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz -o /tmp/ruby.tar.gz; \
    mkdir -p /tmp/ruby-src; tar -xzf /tmp/ruby.tar.gz -C /tmp/ruby-src --strip-components=1; \
    cd /tmp/ruby-src; \
    ./configure --disable-install-doc --with-openssl-dir=/usr; \
    make -j"$(nproc)" && make install; \
    rm -rf /tmp/ruby-src /tmp/ruby.tar.gz;

COPY Gemfile Gemfile.lock .ruby-version $APP_PATH

RUN mkdir -p ./vendor && \
    mkdir -p ./vendor/cache
COPY local_packages/grape-middleware-logger-2.4.0.gem ./vendor/cache/

# Install the EXACT bundler version from Gemfile.lock (“BUNDLED WITH”)
RUN set -eux; \
    gem install bundler --no-document

# Deployment settings (allows network, but stays frozen to the lockfile)
# RUN gem install bundler
RUN bundle config set path /app/vendor/cache \
    && bundle config set without 'development test'
RUN bundle install --verbose

RUN bundle config set deployment true

# Optional Install root certificates.

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
    mkdir -p /runtime/etc/crypto-policies/back-ends && \
    if [ -f /etc/crypto-policies/back-ends/opensslcnf.config ]; then \
    cp -a /etc/crypto-policies/back-ends/opensslcnf.config /runtime/etc/crypto-policies/back-ends/; \
    elif [ -f /usr/share/crypto-policies/back-ends/opensslcnf.config ]; then \
    cp -a /usr/share/crypto-policies/back-ends/opensslcnf.config /runtime/etc/crypto-policies/back-ends/; \
    fi && \
    cp -a /usr/bin/openssl /runtime/usr/bin/ && \
    for b in /usr/bin/psql /usr/bin/pg_dump /usr/bin/pg_restore; do \
    cp -a "$b" /runtime/usr/bin/ 2>/dev/null || true; \
    done && \
    mkdir -p /runtime/usr/lib64/ossl-modules && \
    cp -a /usr/lib64/ossl-modules/* /runtime/usr/lib64/ossl-modules/ 2>/dev/null || true

# Provide a minimal OpenSSL config that doesn't rely on system crypto policies
COPY openssl.cnf /runtime/etc/ssl/openssl.cnf
COPY openssl.cnf /runtime/etc/pki/tls/openssl.cnf

# Auto-collect shared library dependencies for Ruby, native gems, and psql
RUN set -eux; \
    mkdir -p /runtime/usr/lib64; \
    targets="/usr/local/bin/ruby /usr/bin/psql /usr/bin/pg_dump /usr/bin/pg_restore"; \
    if [ -d "$APP_PATH/vendor/bundle" ]; then \
    sofiles=$(find "$APP_PATH/vendor/bundle" -type f -name "*.so" || true); \
    targets="$targets $sofiles"; \
    fi; \
    for t in $targets; do \
    [ -f "$t" ] || continue; \
    ldd "$t" | awk '/=> \/|\//{print $3}' | sed -e 's/(0x[0-9a-fA-F]\+)//g' | grep -E '^/' || true; \
    done | sort -u | while read -r lib; do \
    [ -f "$lib" ] || continue; \
    cp -a "$lib" /runtime/usr/lib64/ 2>/dev/null || true; \
    done
RUN set -eux; \
    # Copy commonly required runtime shared libraries (no loop)
    cp -a /usr/lib64/libpq.so.*            /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libssl.so.*           /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libcrypto.so.*        /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libcrypt.so.*         /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libcrypt.so.*             /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libgssapi_krb5.so.*   /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libkrb5.so.*          /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libkrb5support.so.*   /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libk5crypto.so.*      /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libcom_err.so.*       /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libldap.so.*          /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/liblber.so.*          /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libsasl2.so.*         /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libgssapi_krb5.so.*       /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libkrb5.so.*              /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libkrb5support.so.*       /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libk5crypto.so.*          /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libcom_err.so.*           /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libldap*.so.*             /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/liblber.so.*              /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libsasl2.so.*             /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libkeyutils.so.*      /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libkeyutils.so.*          /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libevent-*.so*        /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/libevent-*.so*            /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/liblz4.so.*           /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /lib64/liblz4.so.*               /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libyaml-0.so.*        /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libreadline.so.*      /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libncursesw.so.*      /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libz.so.*             /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libzstd.so.*          /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libgmp.so.*           /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libffi.so.*           /runtime/usr/lib64/ 2>/dev/null || true; \
    cp -a /usr/lib64/libgdbm.so.*          /runtime/usr/lib64/ 2>/dev/null || true; \
    # App
    cp -a $APP_PATH /runtime/app; \
    # Timezone data for TZInfo
    mkdir -p /runtime/usr/share && cp -a /usr/share/zoneinfo /runtime/usr/share/zoneinfo; \
    chmod +x /tmp/docker-entrypoint.sh; cp /tmp/docker-entrypoint.sh /runtime/usr/bin/docker-entrypoint.sh

# Runtime stage (UBI 10 micro)
FROM registry.access.redhat.com/ubi10/ubi-micro:10.0-1754556444

ENV APP_PATH=/app/
ARG RUBY_VERSION=3.4.6
ENV PATH="/usr/local/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/lib64:/lib64:/usr/local/lib"
ENV OPENSSL_MODULES="/usr/lib64/ossl-modules"
ENV OPENSSL_CONF="/etc/pki/tls/openssl.cnf"
ENV HOME="/home/registry"
ENV BUNDLE_PATH="/app/vendor/bundle"

WORKDIR $APP_PATH

# Copy runtime files from builder
COPY --from=builder /runtime/ /

# Create runtime user (ubi-micro lacks useradd)
RUN set -eux; \
    uid=1000; gid=1000; \
    mkdir -p /home/registry; \
    echo "registry:x:${uid}:${gid}:Registry User:/home/registry:/bin/sh" >> /etc/passwd; \
    echo "registry:x:${gid}:" >> /etc/group; \
    chown -R ${uid}:${gid} /app /home/registry
USER 1000

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

EXPOSE 9292
