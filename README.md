<p align="center"><a href="https://gitlab.com/cyberpnkz/rutorrent" target="_blank"><img width="1536" src="https://raw.githubusercontent.com/k44sh/rutorrent/main/.rutorrent.png"></a></p>

<p align="center">
  <a href="https://hub.docker.com/r/k44sh/rutorrent/tags?page=1&ordering=last_updated"><img src="https://img.shields.io/docker/v/k44sh/rutorrent/latest?logo=docker" alt="Latest Version"></a>
  <a href="https://hub.docker.com/r/k44sh/rutorrent/"><img src="https://img.shields.io/docker/image-size/k44sh/rutorrent/latest?logo=docker" alt="Docker Size"></a>
  <a href="https://hub.docker.com/r/k44sh/rutorrent/"><img src="https://img.shields.io:/docker/pulls/k44sh/rutorrent?logo=docker" alt="Docker Pulls"></a>
  <a href="https://gitlab.com/cyberpnkz/rutorrent/-/pipelines/main/latest"><img src="https://img.shields.io/gitlab/pipeline-status/cyberpnkz%2Frutorrent?branch=main&logo=gitlab" alt="Build Status"></a>
  <a href="https://github.com/k44sh/rutorrent"><img src="https://img.shields.io/github/stars/k44sh/rutorrent?logo=github" alt="Github Stars"></a>
</p>

## About

[rTorrent](https://github.com/rakshasa/rtorrent) and [ruTorrent](https://github.com/Novik/ruTorrent) Docker image based on Alpine Linux.<br />
___

## Features

* Run as non-root user
* Multi-platform image
* [NGINX](https://nginx.org/download) with [PHP 8.3](https://www.php.net/releases/8.3/en.php)
* [rTorrent](https://github.com/rakshasa/rtorrent) / [libTorrent](https://github.com/rakshasa/libtorrent) release compiled from source
* Name resolving with [c-ares](https://github.com/rakshasa/rtorrent/wiki/Performance-Tuning#rtrorrent-with-c-ares) for asynchronous DNS requests (including name resolves)
* [ruTorrent](https://github.com/Novik/ruTorrent) release (`v4.3.1`)
* ruTorrent [GeoIP2](https://github.com/Micdu70/geoip2-rutorrent) plugin
* ruTorrent [Filemanager](https://github.com/nelu/rutorrent-filemanager) plugin
* ruTorrent [Ratiocolors](https://github.com/Gyran/rutorrent-ratiocolor) plugin
* ruTorrent [rtModern-Remix](https://github.com/Teal-c/rtModern-Remix) theme
* ruTorrent [QuickBox](https://github.com/TrimmingFool/club-QuickBox) theme
* [Radarr](https://radarr.video)/[Sonarr](https://sonarr.tv) hardlinks compliance
* [mktorrent](https://github.com/Rudde/mktorrent) installed for ruTorrent create plugin
* `WAN IP` address automatically resolved for reporting to the tracker
* `XMLRPC` through nginx over SCGI socket (basic auth optional)
* `WebDAV` on completed downloads (basic auth optional)
* Ability to add a custom ruTorrent `plugin` / `theme`
* Allow specific configuration for `data` folder
* Allow specific configuration for `config` folder

## Radarr / Sonarr Users

It is recommended to use the same `data` volume for `ruTorrent` and `Radarr`/`Sonarr`, in order to have a structure similar to this :

```shell
data
├── downloads
└── media
   ├── movies
   ├── music
   └── tv
```

:information_source: More informations here : [TRaSH Guide](https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/)

## Multi Platform Images

* linux/amd64
* linux/arm64
* linux/arm/v7

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. Edit the compose file with your preferences and run the following command:

```shell
mkdir $(pwd)/{config,data,passwd}
chown ${PUID}:${PGID} $(pwd)/{config,data,passwd}
docker compose up -d
docker compose logs -f
```

### Upgrade

To upgrade, pull the newer image and launch the container:

```shell
docker compose pull
docker compose up -d
```

### Cleanup

```shell
docker compose down -v
rm -rf $(pwd)/{config,data,passwd}
```

### Command line

You can also use the following minimal command:

```shell
mkdir $(pwd)/{config,data,passwd}
chown ${PUID}:${PGID} $(pwd)/{config,data,passwd}
docker run -d --name rutorrent \
  --ulimit nproc=65535 \
  --ulimit nofile=32000:40000 \
  -p 6881:6881/udp \
  -p 8000:8000 \
  -p 8080:8080 \
  -p 9000:9000 \
  -p 50000:50000 \
  -v $(pwd)/config:/config \
  -v $(pwd)/data:/data \
  -v $(pwd)/passwd:/passwd \
  k44sh/rutorrent:latest && \
  docker logs -f rutorrent
```

## Environment variables

### General

* `TZ`: The timezone assigned to the container (default `UTC`)
* `PUID`: rTorrent user id (default `1000`)
* `PGID`: rTorrent group id (default `1000`)
* `CONFIG_PATH`: ruTorrent config path (default `/config`)
* `TOPDIR_PATH`: ruTorrent top directory (default `/data`)
* `DOWNLOAD_PATH`: Downloads path (default `/data/downloads`)
* `WAN_IP`: Public IP address reported to the tracker (default auto resolved with `dig +short myip.opendns.com @resolver1.opendns.com`)
* `MEMORY_LIMIT`: PHP memory limit (default `512M`)
* `UPLOAD_MAX_SIZE`: Upload max size (default `16M`)
* `CLEAR_ENV`: Clear environment in FPM workers (default `yes`)
* `OPCACHE_MEM_SIZE`: PHP OpCache memory consumption (default `256`)
* `MAX_FILE_UPLOADS`: The maximum number of files allowed to be uploaded simultaneously (default `50`)
* `AUTH_DELAY`: The time in seconds to wait for Basic Auth (default `0s`)
* `REAL_IP_FROM`: Trusted addresses that are known to send correct replacement addresses (default `0.0.0.0/32`)
* `REAL_IP_HEADER`: Request header field whose value will be used to replace the client address (default `X-Forwarded-For`)
* `LOG_IP_VAR`: Use another variable to retrieve the remote IP address for access [log_format](http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format) on Nginx. (default `remote_addr`)
* `XMLRPC_AUTHBASIC_STRING`: Message displayed during validation of XMLRPC Basic Auth (default `rTorrent XMLRPC restricted access`)
* `XMLRPC_PORT`: XMLRPC port through nginx over SCGI socket (default `8000`)
* `XMLRPC_SIZE_LIMIT`: Maximum body size of XMLRPC calls (default `2M`)
* `RUTORRENT_AUTHBASIC_STRING`: Message displayed during validation of ruTorrent Basic Auth (default `ruTorrent restricted access`)
* `RUTORRENT_PORT`: ruTorrent HTTP port (default `8080`)
* `WEBDAV_AUTHBASIC_STRING`: Message displayed during validation of WebDAV Basic Auth (default `WebDAV restricted access`)
* `WEBDAV_PORT`: WebDAV port on completed downloads (default `9000`)

### rTorrent

* `RT_LOG_LEVEL`: rTorrent log level (default `info`)
* `RT_LOG_EXECUTE`: Log executed commands to `/config/rtorrent/log/execute.log` (default `false`)
* `RT_LOG_XMLRPC`: Log XMLRPC queries to `/config/rtorrent/log/xmlrpc.log` (default `false`)
* `RT_SESSION_SAVE_SECONDS`: Seconds between writing torrent information to disk (default `3600`)
* `RT_DHT_PORT`: DHT UDP port (`dht.port.set`, default `6881`)
* `RT_INC_PORT`: Incoming connections (`network.port_range.set`, default `50000`)

### ruTorrent

* `RU_REMOVE_CORE_PLUGINS`: Remove ruTorrent core plugins ; comma separated (default `false`)
* `RU_HTTP_USER_AGENT`: ruTorrent HTTP user agent (default `Mozilla/5.0 (Windows NT 6.0; WOW64; rv:12.0) Gecko/20100101 Firefox/12.0`)
* `RU_HTTP_TIME_OUT`: ruTorrent HTTP timeout in seconds (default `30`)
* `RU_HTTP_USE_GZIP`: Use HTTP Gzip compression (default `true`)
* `RU_RPC_TIME_OUT`: ruTorrent RPC timeout in seconds (default `5`)
* `RU_LOG_RPC_CALLS`: Log ruTorrent RPC calls (default `false`)
* `RU_LOG_RPC_FAULTS`: Log ruTorrent RPC faults (default `true`)
* `RU_PHP_USE_GZIP`: Use PHP Gzip compression (default `false`)
* `RU_PHP_GZIP_LEVEL`: PHP Gzip compression level (default `2`)
* `RU_SCHEDULE_RAND`: Rand for schedulers start, +0..X seconds (default `10`)
* `RU_LOG_FILE`: ruTorrent log file path for errors messages (default `/config/rutorrent/rutorrent.log`)
* `RU_DO_DIAGNOSTIC`: ruTorrent diagnostics like permission checking (default `true`)
* `RU_CACHED_PLUGIN_LOADING`: Set to `true` to enable rapid cached loading of ruTorrent plugins (default `false`)
* `RU_SAVE_UPLOADED_TORRENTS`: Save torrents files added wia ruTorrent in `/config/rutorrent/share/torrents` (default `true`)
* `RU_OVERWRITE_UPLOADED_TORRENTS`: Existing .torrent files will be overwritten (default `false`)
* `RU_FORBID_USER_SETTINGS`: If true, allows for single user style configuration, even with webauth (default `false`)
* `RU_LOCALE`: Set default locale for ruTorrent (default `UTF8`)

## Volumes

* `/config`: rTorrent / ruTorrent config, session files, log, ...
* `/data`: Downloaded files
* `/passwd`: Contains htpasswd files for basic auth

> :information_source: Note that the volumes should be owned by the user/group with the specified `PUID` and `PGID`. If you don't
> give the volumes correct permissions, the container may not start.

## Ports

* `6881` (or `RT_DHT_PORT`): DHT UDP port (`dht.port.set`)
* `8000` (or `XMLRPC_PORT`): XMLRPC port through nginx over SCGI socket
* `8080` (or `RUTORRENT_PORT`): ruTorrent HTTP port
* `9000` (or `WEBDAV_PORT`): WebDAV port on completed downloads
* `50000` (or `RT_INC_PORT`): Incoming connections (`network.port_range.set`)

> :information_source: Port p+1 defined for `XMLRPC_PORT`, `RUTORRENT_PORT` and `WEBDAV_PORT` will also be reserved for
> healthcheck. (e.g. if you define `RUTORRENT_PORT=8080`, port `8081` will be reserved)

## Notes

### XMLRPC through nginx

rTorrent 0.9.7+ has a built-in daemon mode disabling the user interface, so you can only control it via XMLRPC. Nginx
will route XMLRPC requests to rtorrent through port `8000`. These requests can be secured with basic authentication
through the `/passwd/rpc.htpasswd` file in which you will need to add a username with his password. See below to
populate this file with a user / password.

### WebDAV

WebDAV allows you to retrieve your completed torrent files in `/data` on port `9000`. Like XMLRPC, these
requests can be secured with basic authentication through the `/passwd/webdav.htpasswd` file in which you will need to
add a username with his password. See below to populate this file with a user / password.

### Populate .htpasswd files

For ruTorrent basic auth, XMLRPC through nginx and WebDAV on completed downloads, you can populate `.htpasswd`
files with the following command:

```
docker run --rm -it httpd:2.4-alpine htpasswd -Bbn <username> <password> >> $(pwd)/passwd/webdav.htpasswd
```

Htpasswd files used:

* `rpc.htpasswd`: XMLRPC through nginx
* `rutorrent.htpasswd`: ruTorrent basic auth
* `webdav.htpasswd`: WebDAV on completed downloads

### Override or add a ruTorrent plugin/theme

You can add a plugin for ruTorrent in `/config/rutorrent/plugins/`.

If you add a plugin that already exists in ruTorrent,
it will be removed from ruTorrent core plugins and yours will be used. And you can also add a theme in
`/config/rutorrent/themes/`. The same principle as for plugins will be used if you want to override one.

> :information_source: Container has to be restarted to propagate changes

### Edit a ruTorrent plugin configuration

As you probably know, plugin configuration is not outsourced in ruTorrent. Loading the configuration of a plugin is
done via a `conf.php` file placed at the root of the plugin folder. To solve this issue with Docker, a special folder
has been created in `/config/rutorrent/plugins-conf` to allow you to configure plugins. For example to configure the
`diskspace` plugin, you will need to create the `/config/rutorrent/plugins-conf/diskspace.php` file with your
configuration:

```php
<?php

$diskUpdateInterval = 10;	// in seconds
$notifySpaceLimit = 512;	// in Mb
$partitionDirectory = null;	// if null, then we will check rtorrent download directory (or $topDirectory if rtorrent is unavailable) 
```

> :information_source: Container has to be restarted to propagate changes

### Increase Docker timeout to allow rTorrent to shutdown gracefully

After issuing a shutdown command, Docker waits 10 seconds for the container to exit before it is killed.  If you are a seeding many torrents, rTorrent may be unable to gracefully close within that time period.  As a result, rTorrent is closed forcefully and the lockfile isn't removed.  This stale lockfile will prevent rTorrent from restarting until the lockfile is removed manually.

The timeout period can be extended by either adding the parameter `-t XX` to the docker command or `stop_grace_period: XXs` in docker-compose.yml, where `XX` is the number of seconds to wait for a graceful shutdown.

Fork based on the version of [CrazyMax](https://github.com/crazy-max/docker-rtorrent-rutorrent)
