ARG ALPINE_VERSION=3.19
ARG LIBSIG_VERSION=3.0.7
ARG CARES_VERSION=1.23.0
ARG CURL_VERSION=8.5.0
ARG GEOIP2_PHPEXT_VERSION=1.3.1
ARG XMLRPC_VERSION=01.60.00
ARG LIBTORRENT_VERSION=0.13.8
ARG RTORRENT_VERSION=0.9.8

ARG RUTORRENT_REVISION=b317183c25974dd18e9c27a4cab0c598b49ef94f
ARG GEOIP2_REVISION=dfbf6de79026f9d56a0443f45a6bd6283d740b9a
ARG FILEMANAGER_REVISION=3e4e06a905717396771702e66383fb6ef9c41544
ARG RATIOCOLOR_REVISION=3ab4962be86d17fb83649b6db44767796ee377de
ARG MATERIALDESIGN_REVISION=40dd95ee884ec4b678ac4d45711154b018df3eb5
ARG QUICKBOX_REVISION=eb63ee8a246681b6c330379daa431c9644111ee9
ARG RTMODERN_REVISION=6babe10167b0b90a0e0d86ad9859f4d27732b5d8

FROM alpine:${ALPINE_VERSION} AS compile

ENV DIST_PATH="/dist"

RUN apk --update --no-cache add mm-common --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN apk --update --no-cache add \
    autoconf \
    automake \
    binutils \
    brotli-dev \
    build-base \
    curl \
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
    php83-dev \
    php83-pear \
    subversion \
    tar \
    tree \
    xz \
    zlib-dev

ARG LIBSIG_VERSION
WORKDIR /tmp/libsig
RUN curl -sSL "http://ftp.gnome.org/pub/GNOME/sources/libsigc++/3.0/libsigc++-${LIBSIG_VERSION}.tar.xz" | tar -xJ --strip 1
RUN ./autogen.sh --prefix=/usr/local
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
RUN phpize83
RUN ./configure --with-php-config=/usr/bin/php-config83
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
RUN mkdir -p ${DIST_PATH}/usr/lib/php83/modules
RUN cp -f /usr/lib/php83/modules/geoip.so ${DIST_PATH}/usr/lib/php83/modules/

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

ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS download

RUN apk --update --no-cache add curl git tar xz

ARG RUTORRENT_REVISION
WORKDIR /dist/rutorrent
RUN git clone -q "https://github.com/Novik/ruTorrent" . && git reset --hard ${RUTORRENT_REVISION} && rm -rf .git
RUN rm -rf conf/users plugins/geoip plugins/_cloudflare share

ARG GEOIP2_REVISION
WORKDIR /dist/rutorrent-geoip2
RUN git clone -q "https://github.com/Micdu70/geoip2-rutorrent" . && git reset --hard ${GEOIP2_REVISION} && rm -rf .git

ARG FILEMANAGER_REVISION
WORKDIR /dist/rutorrent-filemanager
RUN git clone -q "https://github.com/nelu/rutorrent-filemanager" . && git reset --hard ${FILEMANAGER_REVISION} 

ARG RATIOCOLOR_REVISION
WORKDIR /dist/rutorrent-ratio
RUN git clone -q "https://github.com/Gyran/rutorrent-ratiocolor" . && git reset --hard ${RATIOCOLOR_REVISION} && rm -rf .git

ARG MATERIALDESIGN_REVISION
WORKDIR /dist/rutorrent-theme-material
RUN git clone -q "https://github.com/TrimmingFool/ruTorrent-MaterialDesign" . && git reset --hard ${MATERIALDESIGN_REVISION} && rm -rf .git

ARG QUICKBOX_REVISION
WORKDIR /dist/rutorrent-theme-quick
RUN git clone -q "https://github.com/TrimmingFool/club-QuickBox" . && git reset --hard ${QUICKBOX_REVISION} && rm -rf .git

ARG RTMODERN_REVISION
WORKDIR /dist/rutorrent-theme-rtmodern-remix
RUN git clone -q "https://github.com/Teal-c/rtModern-Remix" . && git reset --hard ${RTMODERN_REVISION} && rm -rf .git \
    && cp -ar /dist/rutorrent-theme-rtmodern-remix /dist/rutorrent-theme-rtmodern-remix-plex \
    && cat themes/plex.css > custom.css \
    && cp -ar /dist/rutorrent-theme-rtmodern-remix /dist/rutorrent-theme-rtmodern-remix-jellyfin \
    && cat themes/jellyfin.css > custom.css \
    && cp -ar /dist/rutorrent-theme-rtmodern-remix /dist/rutorrent-theme-rtmodern-remix-jellyfin-bg \
    && cat themes/jellyfin-bg.css > custom.css \
    && cp -ar /dist/rutorrent-theme-rtmodern-remix /dist/rutorrent-theme-rtmodern-remix-lightpink \
    && cat themes/light-pink.css > custom.css

WORKDIR /dist/mmdb
RUN curl -SsOL "https://github.com/crazy-max/geoip-updater/raw/mmdb/GeoLite2-City.mmdb"
RUN curl -SsOL "https://github.com/crazy-max/geoip-updater/raw/mmdb/GeoLite2-Country.mmdb"

ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} as builder

ENV PYTHONPATH="$PYTHONPATH:/var/www/rutorrent" \
  S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  S6_KILL_GRACETIME="5000" \
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
    mktorrent \
    openssl \
    pcre \
    php83 \
    php83-bcmath \
    php83-cli \
    php83-ctype \
    php83-curl \
    php83-dom \
    php83-fpm \
    php83-json \
    php83-mbstring \
    php83-openssl \
    php83-opcache \
    php83-pecl-apcu \
    php83-pear \
    php83-phar \
    php83-posix \
    php83-session \
    php83-sockets \
    php83-xml \
    php83-zip \
    php83-zlib \
    python3 \
    py3-pip \
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
  && addgroup -g ${PGID} rtorrent \
  && adduser -D -H -u ${PUID} -G rtorrent -s /bin/sh rtorrent \
  && rm -rf /tmp/* /var/cache/apk/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/php83/access.log && \
    ln -sf /dev/stderr /var/log/php83/error.log

COPY rootfs /
COPY --from=compile /dist /
COPY --from=download /dist/mmdb /var/mmdb
COPY --from=download --chown=nobody:nogroup /dist/rutorrent /var/www/rutorrent
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-geoip2 /var/www/rutorrent/plugins/geoip2
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-filemanager /var/www/rutorrent/plugins/filemanager
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-ratio /var/www/rutorrent/plugins/ratiocolor
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-material /var/www/rutorrent/plugins/theme/themes/MaterialDesign
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-quick /var/www/rutorrent/plugins/theme/themes/QuickBox
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix /var/www/rutorrent/plugins/theme/themes/Remix
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix-plex /var/www/rutorrent/plugins/theme/themes/Plex
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix-jellyfin /var/www/rutorrent/plugins/theme/themes/Jellyfin
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix-jellyfin-bg /var/www/rutorrent/plugins/theme/themes/Jellyfin-bg
COPY --from=download --chown=nobody:nogroup /dist/rutorrent-theme-rtmodern-remix-lightpink /var/www/rutorrent/plugins/theme/themes/LightPink

VOLUME [ "/config", "/data", "/passwd" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD /usr/local/bin/healthcheck