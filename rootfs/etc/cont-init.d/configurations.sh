#!/usr/bin/with-contenv sh

echo=echo
for cmd in echo /bin/echo; do
	$cmd >/dev/null 2>&1 || continue
	if ! $cmd -e "" | grep -qE '^-e'; then
		echo=$cmd
		break
	fi
done

cli=$($echo -e "\033[")
norm="${cli}0m"
bold="${cli}1;37m"
red="${cli}1;31m"
green="${cli}1;32m"
yellow="${cli}1;33m"
blue="${cli}1;34m"

echo -e "\n${bold}rTorrent/ruTorrent Configuration${norm}\n"

# General
CONFIG_PATH=${CONFIG_PATH:-/config}
TOPDIR_PATH=${TOPDIR_PATH:-/data}
DOWNLOAD_PATH=${DOWNLOAD_PATH:-${TOPDIR_PATH}/downloads}
WAN_IP=${WAN_IP:-$(dig +short myip.opendns.com @resolver1.opendns.com)}
TZ=${TZ:-UTC}
MEMORY_LIMIT=${MEMORY_LIMIT:-512M}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-16M}
CLEAR_ENV=${CLEAR_ENV:-yes}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-256}
MAX_FILE_UPLOADS=${MAX_FILE_UPLOADS:-50}
AUTH_DELAY=${AUTH_DELAY:-0s}
REAL_IP_FROM=${REAL_IP_FROM:-0.0.0.0/32}
REAL_IP_HEADER=${REAL_IP_HEADER:-X-Forwarded-For}
LOG_IP_VAR=${LOG_IP_VAR:-remote_addr}
XMLRPC_SIZE_LIMIT=${XMLRPC_SIZE_LIMIT:-2M}
XMLRPC_AUTHBASIC_STRING=${XMLRPC_AUTHBASIC_STRING:-rTorrent XMLRPC restricted access}
RUTORRENT_AUTHBASIC_STRING=${RUTORRENT_AUTHBASIC_STRING:-ruTorrent restricted access}
WEBDAV_AUTHBASIC_STRING=${WEBDAV_AUTHBASIC_STRING:-WebDAV restricted access}
XMLRPC_PORT=${XMLRPC_PORT:-8000}
XMLRPC_HEALTH_PORT=$((XMLRPC_PORT + 1))
RUTORRENT_PORT=${RUTORRENT_PORT:-8080}
RUTORRENT_HEALTH_PORT=$((RUTORRENT_PORT + 1))
WEBDAV_PORT=${WEBDAV_PORT:-9000}
WEBDAV_HEALTH_PORT=$((WEBDAV_PORT + 1))

# rTorrent
RT_LOG_LEVEL=${RT_LOG_LEVEL:-info}
RT_LOG_EXECUTE=${RT_LOG_EXECUTE:-false}
RT_LOG_XMLRPC=${RT_LOG_XMLRPC:-false}
RT_DHT_PORT=${RT_DHT_PORT:-6881}
RT_INC_PORT=${RT_INC_PORT:-50000}
RT_SESSION_SAVE_SECONDS=${RT_SESSION_SAVE_SECONDS:-3600}

# ruTorrent
RU_HTTP_USER_AGENT=${RU_HTTP_USER_AGENT:-Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/120.0}
RU_HTTP_TIME_OUT=${RU_HTTP_TIME_OUT:-30}
RU_HTTP_USE_GZIP=${RU_HTTP_USE_GZIP:-true}
RU_RPC_TIME_OUT=${RU_RPC_TIME_OUT:-5}
RU_LOG_RPC_CALLS=${RU_LOG_RPC_CALLS:-false}
RU_LOG_RPC_FAULTS=${RU_LOG_RPC_FAULTS:-true}
RU_PHP_USE_GZIP=${RU_PHP_USE_GZIP:-false}
RU_PHP_GZIP_LEVEL=${RU_PHP_GZIP_LEVEL:-2}
RU_SCHEDULE_RAND=${RU_SCHEDULE_RAND:-10}
RU_LOG_FILE=${RU_LOG_FILE:-${CONFIG_PATH}/rutorrent/rutorrent.log}
RU_DO_DIAGNOSTIC=${RU_DO_DIAGNOSTIC:-true}
RU_CACHED_PLUGIN_LOADING=${RU_CACHED_PLUGIN_LOADING:-false}
RU_REMOVE_CORE_PLUGINS=${RU_REMOVE_CORE_PLUGINS:-false}
RU_SAVE_UPLOADED_TORRENTS=${RU_SAVE_UPLOADED_TORRENTS:-true}
RU_OVERWRITE_UPLOADED_TORRENTS=${RU_OVERWRITE_UPLOADED_TORRENTS:-false}
RU_FORBID_USER_SETTINGS=${RU_FORBID_USER_SETTINGS:-false}
RU_LOCALE=${RU_LOCALE:-UTF8}

printf "%s" "$WAN_IP" > /var/run/s6/container_environment/WAN_IP

# Fix permissions
chown ${PUID}:${PGID} /proc/self/fd/1 /proc/self/fd/2 || true
if [ -n "${PGID}" ] && [ "${PGID}" != "$(id -g rtorrent)" ]; then
  sed -i -e "s/^rtorrent:\([^:]*\):[0-9]*/rtorrent:\1:${PGID}/" /etc/group
  sed -i -e "s/^rtorrent:\([^:]*\):\([0-9]*\):[0-9]*/rtorrent:\1:\2:${PGID}/" /etc/passwd
fi
if [ -n "${PUID}" ] && [ "${PUID}" != "$(id -u rtorrent)" ]; then
  sed -i -e "s/^rtorrent:\([^:]*\):[0-9]*:\([0-9]*\)/rtorrent:\1:${PUID}:\2/" /etc/passwd
fi

# Timezone
echo "  ${norm}[${green}+${norm}] Setting timezone to ${green}${TZ}${norm}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# PHP
echo "  ${norm}[${green}+${norm}] Setting PHP-FPM configuration..."
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
    -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
    -e "s/@CLEAR_ENV@/$CLEAR_ENV/g" \
    -i /etc/php83/php-fpm.d/www.conf

echo "  ${norm}[${green}+${norm}] Setting PHP INI configuration..."
sed -e "s|memory_limit.*|memory_limit = ${MEMORY_LIMIT}|g" \
    -e "s|;date\.timezone.*|date\.timezone = ${TZ}|g" \
    -e "s|max_file_uploads.*|max_file_uploads = ${MAX_FILE_UPLOADS}|g"  \
    -i /etc/php83/php.ini

# OpCache
echo "  ${norm}[${green}+${norm}] Setting OpCache configuration..."
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
    -i /etc/php83/conf.d/opcache.ini

# Nginx
echo "  ${norm}[${green}+${norm}] Setting Nginx configuration..."
sed -e "s#@REAL_IP_FROM@#$REAL_IP_FROM#g" \
    -e "s#@REAL_IP_HEADER@#$REAL_IP_HEADER#g" \
    -e "s#@LOG_IP_VAR@#$LOG_IP_VAR#g" \
    -e "s#@AUTH_DELAY@#$AUTH_DELAY#g" \
    -i /etc/nginx/nginx.conf

# Nginx XMLRPC over SCGI
echo "  ${norm}[${green}+${norm}] Setting Nginx XMLRPC over SCGI configuration..."
sed -e "s!@XMLRPC_AUTHBASIC_STRING@!$XMLRPC_AUTHBASIC_STRING!g" \
    -e "s!@XMLRPC_PORT@!$XMLRPC_PORT!g" \
    -e "s!@XMLRPC_HEALTH_PORT@!$XMLRPC_HEALTH_PORT!g" \
    -e "s!@XMLRPC_SIZE_LIMIT@!$XMLRPC_SIZE_LIMIT!g" \
    -i /etc/nginx/conf.d/rpc.conf

# Nginx ruTorrent
echo "  ${norm}[${green}+${norm}] Setting Nginx ruTorrent configuration..."
sed -e "s!@UPLOAD_MAX_SIZE@!$UPLOAD_MAX_SIZE!g" \
    -e "s!@RUTORRENT_AUTHBASIC_STRING@!$RUTORRENT_AUTHBASIC_STRING!g" \
    -e "s!@RUTORRENT_PORT@!$RUTORRENT_PORT!g" \
    -e "s!@RUTORRENT_HEALTH_PORT@!$RUTORRENT_HEALTH_PORT!g" \
    -i /etc/nginx/conf.d/rutorrent.conf

# Nginx WebDAV
echo "  ${norm}[${green}+${norm}] Setting Nginx WebDAV configuration..."
sed -e "s!@WEBDAV_AUTHBASIC_STRING@!$WEBDAV_AUTHBASIC_STRING!g" \
  -e "s!@WEBDAV_PORT@!$WEBDAV_PORT!g" \
  -e "s!@WEBDAV_HEALTH_PORT@!$WEBDAV_HEALTH_PORT!g" \
  -e "s!@DOWNLOAD_PATH@!$DOWNLOAD_PATH!g" \
  -i /etc/nginx/conf.d/webdav.conf

# Healthcheck
echo "  ${norm}[${green}+${norm}] Setting healthcheck script..."
cat > /usr/local/bin/healthcheck <<EOL
#!/usr/bin/env sh
set -e

# rTorrent
curl --fail -d "<?xml version='1.0'?><methodCall><methodName>system.api_version</methodName></methodCall>" http://127.0.0.1:${XMLRPC_HEALTH_PORT}

# ruTorrent / PHP
curl --fail http://127.0.0.1:${RUTORRENT_HEALTH_PORT}/ping

# WebDAV
curl --fail http://127.0.0.1:${WEBDAV_HEALTH_PORT}
EOL

# Init
echo "  ${norm}[${green}+${norm}] Setting files and folders..."
mkdir -p /passwd \
  /etc/nginx/conf.d \
  /etc/rtorrent \
  /var/cache/nginx \
  /var/lib/nginx \
  /var/run/nginx \
  /var/run/php-fpm \
  /var/run/rtorrent \
  ${CONFIG_PATH}/geoip \
  ${CONFIG_PATH}/rtorrent/log \
  ${CONFIG_PATH}/rtorrent/.session \
  ${CONFIG_PATH}/rtorrent/watch \
  ${CONFIG_PATH}/rutorrent/conf/users \
  ${CONFIG_PATH}/rutorrent/plugins \
  ${CONFIG_PATH}/rutorrent/plugins-conf \
  ${CONFIG_PATH}/rutorrent/share/users \
  ${CONFIG_PATH}/rutorrent/share/torrents \
  ${CONFIG_PATH}/rutorrent/share/settings \
  ${CONFIG_PATH}/rutorrent/themes \
  ${DOWNLOAD_PATH} \
  ${TOPDIR_PATH}

touch /passwd/rpc.htpasswd \
  /passwd/rutorrent.htpasswd \
  /passwd/webdav.htpasswd \
  ${CONFIG_PATH}/rtorrent/log/rtorrent.log \
  ${RU_LOG_FILE}

rm -f ${CONFIG_PATH}/rtorrent/.session/rtorrent.lock

# Check htpasswd files
if [ ! -s "/passwd/rpc.htpasswd" ]; then
  echo "  ${norm}[${yellow}+${norm}] rpc.htpasswd is empty, removing authentication..."
  sed -i "s!auth_basic .*!#auth_basic!g" /etc/nginx/conf.d/rpc.conf
  sed -i "s!auth_basic_user_file.*!#auth_basic_user_file!g" /etc/nginx/conf.d/rpc.conf
fi
if [ ! -s "/passwd/rutorrent.htpasswd" ]; then
  echo "  ${norm}[${yellow}+${norm}] rutorrent.htpasswd is empty, removing authentication..."
  sed -i "s!auth_basic .*!#auth_basic!g" /etc/nginx/conf.d/rutorrent.conf
  sed -i "s!auth_basic_user_file.*!#auth_basic_user_file!g" /etc/nginx/conf.d/rutorrent.conf
fi
if [ ! -s "/passwd/webdav.htpasswd" ]; then
  echo "  ${norm}[${yellow}+${norm}] webdav.htpasswd is empty, removing authentication..."
  sed -i "s!auth_basic .*!#auth_basic!g" /etc/nginx/conf.d/webdav.conf
  sed -i "s!auth_basic_user_file.*!#auth_basic_user_file!g" /etc/nginx/conf.d/webdav.conf
fi

# rTorrent local config
echo "  ${norm}[${green}+${norm}] Checking rTorrent local configuration..."
sed -e "s!@RT_LOG_LEVEL@!$RT_LOG_LEVEL!g" \
    -e "s!@RT_DHT_PORT@!$RT_DHT_PORT!g" \
    -e "s!@RT_INC_PORT@!$RT_INC_PORT!g" \
    -e "s!@XMLRPC_SIZE_LIMIT@!$XMLRPC_SIZE_LIMIT!g" \
    -e "s!@RT_SESSION_SAVE_SECONDS@!$RT_SESSION_SAVE_SECONDS!g" \
    -e "s!@CONFIG_PATH@!$CONFIG_PATH!g" \
    -e "s!@DOWNLOAD_PATH@!$DOWNLOAD_PATH!g" \
    -i /etc/rtorrent/.rtlocal.rc
if [ "${RT_LOG_EXECUTE}" = "true" ]; then
  echo "    ${norm}[${blue}-${norm}] Enabling rTorrent execute log..."
  sed -i "s!#log\.execute.*!log\.execute = (cat,(cfg.logs),\"execute.log\")!g" /etc/rtorrent/.rtlocal.rc
fi
if [ "${RT_LOG_XMLRPC}" = "true" ]; then
  echo "    ${norm}[${blue}-${norm}] Enabling rTorrent xmlrpc log..."
  sed -i "s!#log\.xmlrpc.*!log\.xmlrpc = (cat,(cfg.logs),\"xmlrpc.log\")!g" /etc/rtorrent/.rtlocal.rc
fi

# rTorrent config
echo "  ${norm}[${green}+${norm}] Checking rTorrent configuration..."
if [ ! -f ${CONFIG_PATH}/rtorrent/.rtorrent.rc ]; then
  echo "    ${norm}[${blue}-${norm}] Creating default configuration..."
  cp /etc/rtorrent/.rtorrent.rc ${CONFIG_PATH}/rtorrent/.rtorrent.rc
  chown rtorrent: ${CONFIG_PATH}/rtorrent/.rtorrent.rc
fi

# ruTorrent config
echo "  ${norm}[${green}+${norm}] Bootstrapping ruTorrent configuration..."
cat > /var/www/rutorrent/conf/config.php <<EOL
<?php

// For snoopy client
\$httpUserAgent = '${RU_HTTP_USER_AGENT}';
\$httpTimeOut = ${RU_HTTP_TIME_OUT};
\$httpUseGzip = ${RU_HTTP_USE_GZIP};

// For xmlrpc actions
\$rpcTimeOut = ${RU_RPC_TIME_OUT};
\$rpcLogCalls = ${RU_LOG_RPC_CALLS};
\$rpcLogFaults = ${RU_LOG_RPC_FAULTS};

// For php
\$phpUseGzip = ${RU_PHP_USE_GZIP};
\$phpGzipLevel = ${RU_PHP_GZIP_LEVEL};

// Rand for schedulers start, +0..X seconds
\$schedule_rand = ${RU_SCHEDULE_RAND};

// Path to log file (comment or leave blank to disable logging)
\$log_file = '${RU_LOG_FILE}';
\$do_diagnostic = ${RU_DO_DIAGNOSTIC};

// Set to true if rTorrent is hosted on the SAME machine as ruTorrent
\$localHostedMode = true;

// Set to true to enable rapid cached loading of ruTorrent plugins
// Required to clear web browser cache during version upgrades
\$cachedPluginLoading = ${RU_CACHED_PLUGIN_LOADING};

// Save uploaded torrents to profile/torrents directory or not
\$saveUploadedTorrents = ${RU_SAVE_UPLOADED_TORRENTS};

// Overwrite existing uploaded torrents in profile/torrents directory or make unique name
\$overwriteUploadedTorrents = ${RU_OVERWRITE_UPLOADED_TORRENTS};

// Upper available directory. Absolute path with trail slash.
\$topDirectory = '${TOPDIR_PATH}';
\$forbidUserSettings = ${RU_FORBID_USER_SETTINGS};

// For web->rtorrent link through unix domain socket
\$scgi_port = 0;
\$scgi_host = "unix:///var/run/rtorrent/scgi.socket";
\$XMLRPCMountPoint = "/RPC2"; // DO NOT DELETE THIS LINE!!! DO NOT COMMENT THIS LINE!!!
\$throttleMaxSpeed = 327625*1024; // DO NOT EDIT THIS LINE!!! DO NOT COMMENT THIS LINE!!!

\$pathToExternals = array(
    "php"    => '$(which php83)',
    "curl"   => '',
    "gzip"   => '',
    "7z"     => '',
    "id"     => '',
    "stat"   => '',
    "python" => '$(which python3)',
);

// List of local interfaces
\$localhosts = array(
    "127.0.0.1",
    "localhost",
);

// Path to user profiles
\$profilePath = '${CONFIG_PATH}/rutorrent/share';
// Mask for files and directory creation in user profiles.
\$profileMask = 0770;

// Temp directory. Absolute path with trail slash. If null, then autodetect will be used.
\$tempDirectory = null;

// If true then use X-Sendfile feature if it exist
\$canUseXSendFile = false;

\$locale = '${RU_LOCALE}';

\$enableCSRFCheck = false; // If true then Origin and Referer will be checked
\$enabledOrigins = array(); // List of enabled domains for CSRF check (only hostnames, without protocols, port etc.). If empty, then will retrieve domain from HTTP_HOST / HTTP_X_FORWARDED_HOST
EOL
chown nobody:nogroup "/var/www/rutorrent/conf/config.php"

# Symlinking ruTorrent config
ln -sf ${CONFIG_PATH}/rutorrent/conf/users /var/www/rutorrent/conf/users
if [ ! -f ${CONFIG_PATH}/rutorrent/conf/access.ini ]; then
  echo "  ${norm}[${green}+${norm}] Symlinking ruTorrent access.ini file..."
  mv /var/www/rutorrent/conf/access.ini ${CONFIG_PATH}/rutorrent/conf/access.ini
  ln -sf ${CONFIG_PATH}/rutorrent/conf/access.ini /var/www/rutorrent/conf/access.ini
fi
chown rtorrent: ${CONFIG_PATH}/rutorrent/conf/access.ini
if [ ! -f ${CONFIG_PATH}/rutorrent/conf/plugins.ini ]; then
  echo "  ${norm}[${green}+${norm}] Symlinking ruTorrent plugins.ini file..."
  mv /var/www/rutorrent/conf/plugins.ini ${CONFIG_PATH}/rutorrent/conf/plugins.ini
  ln -sf ${CONFIG_PATH}/rutorrent/conf/plugins.ini /var/www/rutorrent/conf/plugins.ini
fi
chown rtorrent: ${CONFIG_PATH}/rutorrent/conf/plugins.ini

# Remove ruTorrent core plugins
if [ "$RU_REMOVE_CORE_PLUGINS" != "false" ]; then
  for i in ${RU_REMOVE_CORE_PLUGINS//,/ }
  do
    if [ -z "$i" ]; then continue; fi
    echo "  ${norm}[${green}+${norm}] Removing core plugin ${green}$i${norm}..."
    rm -rf "/var/www/rutorrent/plugins/${i}"
  done
fi

# Override ruTorrent plugins config
echo "  ${norm}[${green}+${norm}] Overriding ruTorrent plugins config (create)..."
cat > /var/www/rutorrent/plugins/create/conf.php <<EOL
<?php

\$useExternal = 'mktorrent';
\$pathToCreatetorrent = '/usr/bin/mktorrent';
\$recentTrackersMaxCount = 15;
EOL
chown nobody:nogroup "/var/www/rutorrent/plugins/create/conf.php"

if [ -f /var/www/rutorrent/plugins/ratiocolor/init.js ]; then
  echo "  ${norm}[${green}+${norm}] Setting ruTorrent ${green}ratiocolor${norm} plugin..."
  sed -i s'/changeWhat = "cell-background";/changeWhat = "font";/'g /var/www/rutorrent/plugins/ratiocolor/init.js
fi

echo "  ${norm}[${green}+${norm}] Setting ruTorrent ${green}filemanager${norm} plugin..."
cat > /var/www/rutorrent/plugins/filemanager/conf.php <<EOL
<?php

global \$pathToExternals;
// set with fullpath to binary or leave empty
\$pathToExternals['7zip'] = '/usr/bin/7z';

\$config['mkdperm'] = 755; // default permission to set to new created directories
\$config['show_fullpaths'] = false; // wheter to show userpaths or full system paths in the UI

\$config['textExtensions'] = 'log|txt|nfo|sfv|xml|html';

// see what 7zip extraction supports as type by file extension
\$config['fileExtractExtensions'] = '7z|bzip2|t?bz2|tgz|gz(ip)?|iso|img|lzma|rar|tar|t?xz|zip|z01|wim';

// archive creation, see archiver man page before editing
// archive.fileExt -> config
\$config['archive']['type'] = [
    '7z' => [
        'bin' =>'7zip',
        'compression' => [1, 5, 9],
    ]];

\$config['archive']['type']['zip'] = \$config['archive']['type']['7z'];
\$config['archive']['type']['tar'] = \$config['archive']['type']['7z'];
\$config['archive']['type']['tar']['has_password'] = false;
\$config['archive']['type']['bz2'] = \$config['archive']['type']['tar'];
\$config['archive']['type']['gz'] = \$config['archive']['type']['tar'];
\$config['archive']['type']['tar.7z'] = \$config['archive']['type']['tar'];
\$config['archive']['type']['tar.bz2'] = \$config['archive']['type']['tar'];
\$config['archive']['type']['tar.gz'] = \$config['archive']['type']['tar'];
\$config['archive']['type']['tar.xz'] = \$config['archive']['type']['tar'];

// multiple passes for archiving and compression
\$config['archive']['type']['tar.gz']['multipass'] = ['tar', 'gzip'];
\$config['archive']['type']['tar.bz2']['multipass'] = ['tar', 'bzip2'];
\$config['archive']['type']['tar.7z']['multipass'] = ['tar', '7z'];
\$config['archive']['type']['tar.xz']['multipass'] = ['tar', 'xz'];
EOL
chown nobody:nogroup "/var/www/rutorrent/plugins/filemanager/conf.php"

# Check ruTorrent plugins
echo "  ${norm}[${green}+${norm}] Checking ruTorrent custom plugins..."
plugins=$(ls -l ${CONFIG_PATH}/rutorrent/plugins | grep -E '^d' | awk '{print $9}')
for plugin in ${plugins}; do
  if [ "${plugin}" = "theme" ]; then
    echo "    ${norm}[${red}-${norm}] ${red}WARNING: Plugin theme cannot be overriden${norm}"
    continue
  fi
  echo "    ${norm}[${blue}+${norm}] Copying custom plugin ${blue}${plugin}${norm}..."
  rm -rf "/var/www/rutorrent/plugins/${plugin}"
  cp -Rf "${CONFIG_PATH}/rutorrent/plugins/${plugin}" "/var/www/rutorrent/plugins/${plugin}"
  chown -R nobody:nogroup "/var/www/rutorrent/plugins/${plugin}"
done

# Check ruTorrent plugins config
echo "  ${norm}[${green}+${norm}] Checking ruTorrent custom plugins configuration..."
for pluginConfFile in ${CONFIG_PATH}/rutorrent/plugins-conf/*.php; do
  if [ ! -f "$pluginConfFile" ]; then
    continue
  fi
  pluginConf=$(basename "$pluginConfFile")
  pluginName=$(echo "$pluginConf" | cut -f 1 -d '.')
  if [ ! -d "/var/www/rutorrent/plugins/${pluginName}" ]; then
    echo "    ${norm}[${red}-${norm}] ${red}WARNING: Plugin $pluginName does not exist${norm}"
    continue
  fi
  if [ -d "${CONFIG_PATH}/rutorrent/plugins/${pluginName}" ]; then
    echo "    ${norm}[${red}-${norm}] ${red}WARNING: Plugin $pluginName already present in ${CONFIG_PATH}/rutorrent/plugins/${norm}"
    continue
  fi
  echo "    ${norm}[${blue}-${norm}] Copying ${blue}${pluginName}${norm} plugin config..."
  cp -f "${pluginConfFile}" "/var/www/rutorrent/plugins/${pluginName}/conf.php"
  chown nobody:nogroup "/var/www/rutorrent/plugins/${pluginName}/conf.php"
done

if [ ! -f ${CONFIG_PATH}/rutorrent/share/settings/theme.dat ]; then
  echo "  ${norm}[${green}+${norm}] Setting ruTorrent ${green}MaterialDesign${norm} theme..."
  echo 'O:6:"rTheme":2:{s:4:"hash";s:9:"theme.dat";s:7:"current";s:14:"MaterialDesign";}' > ${CONFIG_PATH}/rutorrent/share/settings/theme.dat
fi

if [ ! -f ${CONFIG_PATH}/rutorrent/share/settings/unpack.dat ]; then
  echo "  ${norm}[${green}+${norm}] Setting ruTorrent ${green}Unpack${norm} plugin..."
  echo 'O:7:"rUnpack":6:{s:4:"hash";s:10:"unpack.dat";s:7:"enabled";s:1:"1";s:6:"filter";s:4:"/.*/";s:4:"path";s:0:"";s:8:"addLabel";s:1:"0";s:7:"addName";s:1:"0";}' \
  > ${CONFIG_PATH}/rutorrent/share/settings/unpack.dat
fi

# Check ruTorrent themes
echo "  ${norm}[${green}+${norm}] Checking ruTorrent custom themes..."
themes=$(ls -l ${CONFIG_PATH}/rutorrent/themes | grep -E '^d' | awk '{print $9}')
for theme in ${themes}; do
  echo "    ${norm}[${blue}-${norm}] Copying custom theme ${blue}${theme}${norm}..."
  rm -rf "/var/www/rutorrent/plugins/theme/themes/${theme}"
  cp -Rf "${CONFIG_PATH}/rutorrent/themes/${theme}" "/var/www/rutorrent/plugins/theme/themes/${theme}"
  chown -R nobody:nogroup "/var/www/rutorrent/plugins/theme/themes/${theme}"
done

# GeoIP2 databases
echo "  ${norm}[${green}+${norm}] Checking GeoIP2 databases for geoip2 plugin..."
if [ -d "/var/www/rutorrent/plugins/geoip2" ]; then
  if [ ! "$(ls -A ${CONFIG_PATH}/geoip)" ]; then
    cp -f /var/mmdb/*.mmdb ${CONFIG_PATH}/geoip/
  fi
  ln -sf ${CONFIG_PATH}/geoip/GeoLite2-ASN.mmdb /var/www/rutorrent/plugins/geoip2/database/GeoLite2-ASN.mmdb
  ln -sf ${CONFIG_PATH}/geoip/GeoLite2-City.mmdb /var/www/rutorrent/plugins/geoip2/database/GeoLite2-City.mmdb
  ln -sf ${CONFIG_PATH}/geoip/GeoLite2-Country.mmdb /var/www/rutorrent/plugins/geoip2/database/GeoLite2-Country.mmdb
else
  echo "    ${norm}[${red}-${norm}] ${red}WARNING: GeoIP2 does not exist${norm}"
fi

# Perms
echo "  ${norm}[${green}+${norm}] Fixing perms..."
chown rtorrent: \
  ${CONFIG_PATH} \
  ${CONFIG_PATH}/rtorrent \
  ${CONFIG_PATH}/rutorrent \
  ${DOWNLOAD_PATH} \
  ${TOPDIR_PATH} \
  ${RU_LOG_FILE}

chown -R rtorrent: \
  /passwd \
  /etc/rtorrent \
  /var/cache/nginx \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php83 \
  /var/run/nginx \
  /var/run/php-fpm \
  /var/run/rtorrent \
  ${CONFIG_PATH}/geoip \
  ${CONFIG_PATH}/rtorrent/log \
  ${CONFIG_PATH}/rtorrent/.session \
  ${CONFIG_PATH}/rtorrent/watch \
  ${CONFIG_PATH}/rutorrent/conf \
  ${CONFIG_PATH}/rutorrent/plugins \
  ${CONFIG_PATH}/rutorrent/plugins-conf \
  ${CONFIG_PATH}/rutorrent/share \
  ${CONFIG_PATH}/rutorrent/themes

chmod 644 \
  ${CONFIG_PATH}/rtorrent/.rtorrent.rc \
  /passwd/*.htpasswd \
  /etc/rtorrent/.rtlocal.rc

echo -e "  ${norm}[${green}+${norm}] Settings services...\n"
mkdir -p /etc/services.d/nginx
cat > /etc/services.d/nginx/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
nginx -g "daemon off;"
EOL
chmod +x /etc/services.d/nginx/run

mkdir -p /etc/services.d/php-fpm
cat > /etc/services.d/php-fpm/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
php-fpm83 -F
EOL
chmod +x /etc/services.d/php-fpm/run

mkdir -p /etc/services.d/rtorrent
cat > /etc/services.d/rtorrent/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/bin/export HOME ${CONFIG_PATH}/rtorrent
/bin/export PWD ${CONFIG_PATH}/rtorrent
s6-setuidgid ${PUID}:${PGID}
EOL
if [ -z "${WAN_IP}" ]; then
  echo "rtorrent -D -o import=/etc/rtorrent/.rtlocal.rc" >> /etc/services.d/rtorrent/run
else
  echo "rtorrent -D -o import=/etc/rtorrent/.rtlocal.rc -i ${WAN_IP}" >> /etc/services.d/rtorrent/run
fi
chmod +x /etc/services.d/rtorrent/run