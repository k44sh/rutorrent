ARG ALPINE_VERSION=latest
ARG LIBSIG_VERSION=3.6.0
ARG CARES_VERSION=1.34.5
ARG CURL_VERSION=8.13.0
ARG GEOIP2_PHPEXT_VERSION=1.3.1
ARG LIBTORRENT_VERSION=0.15.3
ARG RTORRENT_VERSION=0.15.3
ARG MM_COMMON_VERSION=1.0.6
ARG RUTORRENT_REVISION=2834e153a203778373a7b854ede81e858745fbc1

FROM alpine:${ALPINE_VERSION} AS compile

ENV DIST_PATH="/dist"

RUN apk --update --no-cache add \
    autoconf \
    autoconf-archive \
    automake \
    binutils \
    brotli-dev \
    build-base \
    curl \
    cppunit-dev \
    fftw-dev \
    gd-dev \
    geoip-dev \
    git \
    libnl3 \
    libnl3-dev \
    libtool \
    libpsl-dev \
    libxslt-dev \
    linux-headers \
    ncurses-dev \
    nghttp2-dev \
    openssl-dev \
    pcre-dev \
    php84-dev \
    php84-pear \
    subversion \
    tar \
    tree \
    xz \
    zlib-dev

ARG MM_COMMON_VERSION
WORKDIR /tmp/common
RUN curl -sSL "http://ftp.gnome.org/pub/GNOME/sources/mm-common/1.0/mm-common-${MM_COMMON_VERSION}.tar.xz" | tar -xJ --strip 1
RUN ./autogen.sh --prefix=/usr/local 
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)
RUN cp -r /usr/local/share/aclocal/* /usr/share/aclocal/

ARG LIBSIG_VERSION
WORKDIR /tmp/libsig
RUN curl -sSL "http://ftp.gnome.org/pub/GNOME/sources/libsigc++/3.6/libsigc++-${LIBSIG_VERSION}.tar.xz" | tar -xJ --strip 1
RUN ./autogen.sh --prefix=/usr/local
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG CARES_VERSION
WORKDIR /tmp/cares
RUN curl -sSL "https://github.com/c-ares/c-ares/releases/download/v${CARES_VERSION}/c-ares-${CARES_VERSION}.tar.gz" | tar -xz --strip 1
RUN ./configure
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG CURL_VERSION
WORKDIR /tmp/curl
RUN curl -sSL "https://curl.se/download/curl-${CURL_VERSION}.tar.gz" | tar -xz --strip 1
RUN ./configure \
  --enable-ares \
  --enable-tls-srp \
  --enable-gnu-tls \
  --with-brotli \
  --with-ssl \
  --with-zlib
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG GEOIP2_PHPEXT_VERSION
WORKDIR /tmp/geoip2-phpext
RUN git clone -q "https://github.com/rlerdorf/geoip" . && git reset --hard ${GEOIP2_PHPEXT_VERSION} && rm -rf .git
RUN set -e
RUN phpize84
RUN ./configure --with-php-config=/usr/bin/php-config84
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG LIBTORRENT_VERSION
WORKDIR /tmp/libtorrent
RUN git clone -q "https://github.com/rakshasa/libtorrent" . && git reset --hard v${LIBTORRENT_VERSION} && rm -rf .git
RUN autoreconf -vfi
RUN ./configure --enable-aligned
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG RTORRENT_VERSION
WORKDIR /tmp/rtorrent
RUN git clone -q "https://github.com/rakshasa/rtorrent" . && git reset --hard v${RTORRENT_VERSION} && rm -rf .git
RUN autoreconf -vfi
RUN ./configure --with-xmlrpc-tinyxml2 --with-ncurses
RUN make -j $(nproc) CXXFLAGS="-w -O3 -flto -Werror=odr -Werror=lto-type-mismatch -Werror=strict-aliasing" LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

WORKDIR /tmp/dumptorrent
RUN git clone -q "https://github.com/TheGoblinHero/dumptorrent.git" . && rm -rf .git
RUN sed -i '1i #include <sys/time.h>' scrapec.c
RUN make dumptorrent -j $(nproc) CXXFLAGS="-w -O3 -flto"
RUN cp dumptorrent ${DIST_PATH}/usr/local/bin

RUN tree ${DIST_PATH}

ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS download

RUN apk --update --no-cache add curl git tar xz

ARG RUTORRENT_REVISION
WORKDIR /dist/rutorrent
RUN git clone -q "https://github.com/Novik/ruTorrent" . && git reset --hard ${RUTORRENT_REVISION} && rm -rf .git
RUN rm -rf conf/users plugins/geoip share

WORKDIR /dist/rutorrent-geoip2
RUN git clone -q "https://github.com/Micdu70/geoip2-rutorrent" . && rm -rf .git

WORKDIR /dist/rutorrent-filemanager
RUN git clone -q "https://github.com/nelu/rutorrent-filemanager" . 

WORKDIR /dist/rutorrent-ratio
RUN git clone -q "https://github.com/Gyran/rutorrent-ratiocolor" . && rm -rf .git

WORKDIR /dist/rutorrent-theme-quick
RUN git clone -q "https://github.com/QuickBox/club-QuickBox" . && rm -rf .git

FROM golang:alpine AS geoip2

ARG MM_ACCOUNT
ARG MM_LICENSE
WORKDIR /dist/mmdb
RUN apk --update --no-cache add git
ENV GOPATH=/opt/geoipupdate GOMAXPROCS=1
RUN VERSION=$(git ls-remote --tags "https://github.com/maxmind/geoipupdate"| \
    awk '{print $2}' | sed 's/refs\/tags\///;s/\..*$//' | sort -uV | tail -1) \
    && go install github.com/maxmind/geoipupdate/$VERSION/cmd/geoipupdate@latest
RUN cat > /etc/geoip2.conf <<EOL
AccountID ${MM_ACCOUNT}
LicenseKey ${MM_LICENSE}
EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country
EOL
RUN /opt/geoipupdate/bin/geoipupdate -v -f /etc/geoip2.conf -d ./

ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS builder

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

RUN apk --update --no-cache add unrar --repository=http://dl-cdn.alpinelinux.org/alpine/v3.14/main
RUN apk --update --no-cache add \
    apache2-utils \
    bash \
    bind-tools \
    binutils \
    brotli \
    ca-certificates \
    coreutils \
    ffmpeg \
    findutils \
    geoip \
    grep \
    gzip \
    htop \
    jq \
    libstdc++ \
    mediainfo \
    nano \
    ncurses \
    nginx \
    nginx-mod-http-brotli \
    nginx-mod-http-headers-more \
    nginx-mod-http-dav-ext \
    nginx-mod-http-geoip2 \
    mktorrent \
    openssl \
    php84 \
    php84-bcmath \
    php84-cli \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-fpm \
    php84-json \
    php84-mbstring \
    php84-openssl \
    php84-opcache \
    php84-pecl-apcu \
    php84-pear \
    php84-phar \
    php84-posix \
    php84-session \
    php84-sockets \
    php84-xml \
    php84-zip \
    php84-zlib \
    python3 \
    py3-pip \
    py3-virtualenv \
    p7zip \
    s6-overlay \
    shadow \
    sox \
    tar \
    tzdata \
    unzip \
    util-linux \
    zip \
    zlib \
  && pip3 install --upgrade --break-system-packages pip \
  && pip3 install --break-system-packages cfscrape cloudscraper \
  && addgroup -g ${PGID} rtorrent \
  && adduser -D -H -u ${PUID} -G rtorrent -s /bin/sh rtorrent \
  && rm -rf /tmp/* /var/cache/apk/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/php84/access.log && \
    ln -sf /dev/stderr /var/log/php84/error.log

COPY rootfs /
COPY --from=compile /dist /
COPY --from=geoip2 /dist/mmdb /var/mmdb
COPY --from=geoip2 /opt/geoipupdate/bin/geoipupdate /usr/local/bin/
COPY --from=download --chown=nobody:nogroup /dist/rutorrent /var/www/rutorrent
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-geoip2 /var/www/rutorrent/plugins/geoip2
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-filemanager /var/www/rutorrent/plugins/filemanager
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-ratio /var/www/rutorrent/plugins/ratiocolor
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-quick /var/www/rutorrent/plugins/theme/themes/QuickBox

VOLUME [ "/config", "/data", "/passwd" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD /usr/local/bin/healthcheck
