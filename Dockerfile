ARG ALPINE_VERSION=3.18
ARG ALPINE_S6_VERSION=${ALPINE_VERSION}-2.2.0.3
ARG LIBSIG_VERSION=3.0.3
ARG CARES_VERSION=1.23.0
ARG CURL_VERSION=8.4.0
ARG GEOIP2_PHPEXT_VERSION=1.3.1
ARG XMLRPC_VERSION=01.60.00
ARG LIBTORRENT_VERSION=0.13.8
ARG RTORRENT_VERSION=0.9.8
ARG MKTORRENT_VERSION=1.1

FROM alpine:${ALPINE_VERSION} AS compile

ENV DIST_PATH="/dist"

RUN apk --update --no-cache add \
    autoconf \
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
    libxslt-dev \
    linux-headers \
    ncurses-dev \
    nghttp2-dev \
    openssl-dev \
    pcre-dev \
    php82-dev \
    php82-pear \
    subversion \
    tar \
    tree \
    xz \
    zlib-dev

ARG LIBSIG_VERSION
WORKDIR /tmp/libsig
RUN curl -sSL "http://ftp.gnome.org/pub/GNOME/sources/libsigc++/3.0/libsigc++-${LIBSIG_VERSION}.tar.xz" | tar -xJ --strip 1
RUN ./configure
RUN make -j $(nproc)
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG CARES_VERSION
WORKDIR /tmp/cares
RUN curl -sSL "https://c-ares.org/download/c-ares-${CARES_VERSION}.tar.gz" | tar -xz --strip 1
RUN ./configure
RUN make -j $(nproc) CFLAGS="-O2 -flto"
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
RUN make -j $(nproc) CFLAGS="-O2 -flto -pipe"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG GEOIP2_PHPEXT_VERSION
WORKDIR /tmp/geoip2-phpext
RUN git clone -q "https://github.com/rlerdorf/geoip" . && git reset --hard ${GEOIP2_PHPEXT_VERSION} && rm -rf .git
RUN set -e
RUN phpize82
RUN ./configure --with-php-config=/usr/bin/php-config82
RUN make -j $(nproc)
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG XMLRPC_VERSION
WORKDIR /tmp/xmlrpc-c
RUN svn checkout -q "http://svn.code.sf.net/p/xmlrpc-c/code/release_number/${XMLRPC_VERSION}/" . && rm -rf .svn
RUN ./configure \
   --disable-wininet-client \
   --disable-libwww-client
RUN make -j $(nproc) CXXFLAGS="-flto"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)
RUN mkdir -p ${DIST_PATH}/usr/lib/php82/modules
RUN cp -f /usr/lib/php82/modules/geoip.so ${DIST_PATH}/usr/lib/php82/modules/

ARG LIBTORRENT_VERSION
WORKDIR /tmp/libtorrent
RUN git clone -q "https://github.com/rakshasa/libtorrent" . && git reset --hard v${LIBTORRENT_VERSION} && rm -rf .git
RUN ./autogen.sh
RUN ./configure \
  --with-posix-fallocate
RUN make -j $(nproc) CXXFLAGS="-O2 -flto"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG RTORRENT_VERSION
WORKDIR /tmp/rtorrent
RUN git clone -q "https://github.com/rakshasa/rtorrent" . && git reset --hard v${RTORRENT_VERSION} && rm -rf .git
RUN ./autogen.sh
RUN ./configure \
  --with-xmlrpc-c \
  --with-ncurses
RUN make -j $(nproc) CXXFLAGS="-O2 -flto"
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG MKTORRENT_VERSION
WORKDIR /tmp/mktorrent
RUN git clone -q "https://github.com/esmil/mktorrent" . && git reset --hard v${MKTORRENT_VERSION} && rm -rf .git
RUN make -j $(nproc)
RUN make install -j $(nproc)
RUN make DESTDIR=${DIST_PATH} install -j $(nproc)

ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS download

ENV DIST_PATH="/dist"

RUN apk --update --no-cache add curl git tar xz

WORKDIR /dist/rutorrent
RUN git clone -q "https://github.com/Novik/ruTorrent" . && rm -rf .git
RUN rm -rf conf/users plugins/geoip plugins/_cloudflare share

WORKDIR /dist/rutorrent-geoip2
RUN git clone -q "https://github.com/Micdu70/geoip2-rutorrent" . && rm -rf .git

WORKDIR /dist/rutorrent-filemanager
RUN git clone -q "https://github.com/nelu/rutorrent-filemanager" . && rm -rf .git

WORKDIR /dist/rutorrent-ratio
RUN git clone -q "https://github.com/Gyran/rutorrent-ratiocolor" . && rm -rf .git

WORKDIR /dist/rutorrent-theme-material
RUN git clone -q "https://github.com/TrimmingFool/ruTorrent-MaterialDesign" . && rm -rf .git

WORKDIR /dist/rutorrent-theme-quick
RUN git clone -q "https://github.com/TrimmingFool/club-QuickBox" . && rm -rf .git

WORKDIR /dist/rutorrent-theme-rtmodern-remix
RUN git clone -q "https://github.com/Teal-c/rtModern-Remix" . && rm -rf .git

WORKDIR /dist/rutorrent-theme-rtmodern-remix-plex
RUN git clone -q "https://github.com/Teal-c/rtModern-Remix" . && rm -rf .git
RUN cat themes/plex.css > custom.css

WORKDIR /dist/rutorrent-theme-rtmodern-remix-jellyfin
RUN git clone -q "https://github.com/Teal-c/rtModern-Remix" . && rm -rf .git
RUN cat themes/jellyfin.css > custom.css

WORKDIR /dist/rutorrent-theme-rtmodern-remix-jellyfin-bg
RUN git clone -q "https://github.com/Teal-c/rtModern-Remix" . && rm -rf .git
RUN cat themes/jellyfin-bg.css > custom.css

WORKDIR /dist/rutorrent-theme-rtmodern-remix-lightpink
RUN git clone -q "https://github.com/Teal-c/rtModern-Remix" . && rm -rf .git
RUN cat themes/light-pink.css > custom.css

WORKDIR /dist/mmdb
RUN curl -SsOL "https://github.com/crazy-max/geoip-updater/raw/mmdb/GeoLite2-City.mmdb"
RUN curl -SsOL "https://github.com/crazy-max/geoip-updater/raw/mmdb/GeoLite2-Country.mmdb"

ARG ALPINE_S6_VERSION
FROM crazymax/alpine-s6:${ALPINE_S6_VERSION} as builder

ENV PYTHONPATH="$PYTHONPATH:/var/www/rutorrent" \
  S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  S6_KILL_GRACETIME="10000" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

RUN echo "@314 http://dl-cdn.alpinelinux.org/alpine/v3.14/main" >> /etc/apk/repositories
RUN apk --update --no-cache add \
    apache2-utils \
    bash \
    bind-tools \
    binutils \
    brotli \
    ca-certificates \
    coreutils \
    dhclient \
    ffmpeg \
    findutils \
    geoip \
    grep \
    gzip \
    htop \
    libstdc++ \
    mediainfo \
    nano \
    ncurses \
    nginx \
    nginx-mod-http-brotli \
    nginx-mod-http-headers-more \
    nginx-mod-http-dav-ext \
    nginx-mod-http-geoip2 \
    openssl \
    pcre \
    php82 \
    php82-dev \
    php82-bcmath \
    php82-cli \
    php82-ctype \
    php82-curl \
    php82-dom \
    php82-fpm \
    php82-json \
    php82-mbstring \
    php82-openssl \
    php82-opcache \
    php82-pecl-apcu \
    php82-pear \
    php82-phar \
    php82-posix \
    php82-session \
    php82-sockets \
    php82-xml \
    php82-zip \
    php82-zlib \
    python3 \
    py3-pip \
    p7zip \
    shadow \
    sox \
    tar \
    tzdata \
    unzip \
    unrar@314 \
    util-linux \
    zip \
    zlib \
  && pip3 install --upgrade pip \
  && pip3 install cfscrape cloudscraper \
  && addgroup -g ${PGID} rtorrent \
  && adduser -D -H -u ${PUID} -G rtorrent -s /bin/sh rtorrent \
  && rm -rf /tmp/* /var/cache/apk/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/php82/access.log && \
    ln -sf /dev/stderr /var/log/php82/error.log

COPY rootfs /
COPY --from=compile /dist /
COPY --from=download /dist/mmdb /var/mmdb
COPY --from=download --chown=nobody:nogroup /dist/rutorrent /var/www/rutorrent
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-geoip2 /var/www/rutorrent/plugins/geoip2
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-filemanager /var/www/rutorrent/plugins/filemanager
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-ratio /var/www/rutorrent/plugins/ratiocolor
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-material /var/www/rutorrent/plugins/theme/themes/MaterialDesign
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-quick /var/www/rutorrent/plugins/theme/themes/QuickBox
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix /var/www/rutorrent/plugins/theme/themes/rtModern-Remix
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix-plex /var/www/rutorrent/plugins/theme/themes/rtModern-Plex
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix-jellyfin /var/www/rutorrent/plugins/theme/themes/rtModern-Jellyfin
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix-jellyfin-bg /var/www/rutorrent/plugins/theme/themes/rtModern-Jellyfin-bg
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix-lightpink /var/www/rutorrent/plugins/theme/themes/rtModern-LightPink

RUN curl --version

VOLUME [ "/config", "/data", "/passwd" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD /usr/local/bin/healthcheck