#!/bin/bash

# exit script if return code != 0
set -e

# build scripts
####

# download build scripts from github
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /usr/local/bin/

# custom
####

libtorrentps_package_name="libtorrent-ps.tar.xz"

# download compiled libtorrent-ps (used by rtorrent-ps)
# curly.sh -rc 6 -rw 10 -of "/tmp/${libtorrentps_package_name}" -url "https://github.com/binhex/arch-packages/raw/master/compiled/libtorrent-ps.tar.xz"
curly.sh -rc 6 -rw 10 -of "/tmp/${libtorrentps_package_name}" -url "https://github.com/binhex/arch-packages/raw/master/compiled/libtorrent-ps-1.1.r42.g37c9d4b-1-any.pkg.tar.xz"

# install libtorrent-ps
pacman -U "/tmp/${libtorrentps_package_name}" --noconfirm

rtorrentps_package_name="rtorrent-ps.tar.xz"

# download compiled rtorrent-ps (cannot compile during docker build)
# curly.sh -rc 6 -rw 10 -of "/tmp/${rtorrentps_package_name}" -url "https://github.com/binhex/arch-packages/raw/master/compiled/rtorrent-ps.tar.xz"
curly.sh -rc 6 -rw 10 -of "/tmp/${rtorrentps_package_name}" -url "https://github.com/binhex/arch-packages/raw/master/compiled/rtorrent-ps-1.1.r42.g37c9d4b-1-any.pkg.tar.xz"

# install rtorrent-ps
pacman -U "/tmp/${rtorrentps_package_name}" --noconfirm

# set tmux to use 256 colors (required by rtorrent-ps)
echo 'set -g default-terminal "screen-256color"' > /home/nobody/.tmux.conf

# pacman packages
####

# define pacman packages
pacman_packages="git nginx php-fpm rsync openssl tmux mediainfo php-geoip libx264 libvpx xmlrpc-c sox python2 python-pip"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# uninstall conflicting packages
pacman -R unrar --noconfirm

# define aur packages
aur_packages="autodl-irssi-community rar"

# call aur install script (arch user repo) - note true required due to autodl-irssi error during install
source aur.sh

# github release - rutorrent
####

# download rutorrent
github.sh -df github-rutorrent.zip -dp "/tmp" -ep "/tmp/extracted" -ip "/usr/share/webapps/rutorrent" -go "Novik" -gr "ruTorrent" -rt "source"

# rutorrent plugin cloudflare requires python module 'CfScrape', use pip to install (python-pip = python 3.x)
pip install --ignore-installed CfScrape

# install rutorrent themes and plugins
git clone https://github.com/QuickBox/club-QuickBox /usr/share/webapps/rutorrent/plugins/theme/themes/club-QuickBox
git clone https://github.com/Phlooo/ruTorrent-MaterialDesign /usr/share/webapps/rutorrent/plugins/theme/themes/MaterialDesign
git clone https://github.com/orobardet/rutorrent-force_save_session /usr/share/webapps/rutorrent/plugins/force_save_session
git clone https://github.com/AceP1983/ruTorrent-plugins /usr/share/webapps/rutorrent/plugins/ruTorrent-plugins
mv /usr/share/webapps/rutorrent/plugins/ruTorrent-plugins/* /usr/share/webapps/rutorrent/plugins/
rm -rf /usr/share/webapps/rutorrent/plugins/ruTorrent-plugins
git clone https://github.com/nelu/rutorrent-thirdparty-plugins.git /usr/share/webapps/rutorrent/plugins/rutorrent-thirdparty-plugins
mv /usr/share/webapps/rutorrent/plugins/rutorrent-thirdparty-plugins/* /usr/share/webapps/rutorrent/plugins/
rm -rf /usr/share/webapps/rutorrent/plugins/rutorrent-thirdparty-plugins
chmod 755 /usr/share/webapps/rutorrent/plugins/filemanager/scripts/*
rm -rf /usr/share/webapps/rutorrent/plugins/fileupload
pacman -S cksfv tar zip unzip bzip2  --noconfirm
git clone https://github.com/Gyran/rutorrent-pausewebui /usr/share/webapps/rutorrent/plugins/pausewebui
git clone https://github.com/Gyran/rutorrent-ratiocolor /usr/share/webapps/rutorrent/plugins/ratiocolor
sed -i 's/changeWhat = "cell-background";/changeWhat = "font";/g' /usr/share/webapps/rutorrent/plugins/ratiocolor/init.js
git clone https://github.com/Gyran/rutorrent-instantsearch /usr/share/webapps/rutorrent/plugins/instantsearch
git clone https://github.com/xombiemp/rutorrentMobile /usr/share/webapps/rutorrent/plugins/rutorrentMobile
git clone https://github.com/dioltas/AddZip /usr/share/webapps/rutorrent/plugins/AddZip

# github release - pyrocore
####

# download pyrocore tools for rtorrent-ps
git clone "https://github.com/pyroscope/pyrocore.git" "/opt/pyrocore" && cd "/opt/pyrocore"

# manually create folder, used to create symlinks to pyrocore binaries
mkdir -p "/home/nobody/bin"

# run install script which updates to github head and then installs python modules using pip
./update-to-head.sh "/usr/bin/python2"

# install additional python modules using pip (pip laid on disk as part of pyrocore) - required
# for pycore torque utility
# note we also require gcc to compile python module psutil
pacman -S --needed gcc --noconfirm
/opt/pyrocore/bin/pip install --ignore-installed -r "/opt/pyrocore/requirements-torque.txt"

# once psutil is compiled then remove gcc
pacman -Ru gcc --noconfirm

# github master branch - autodl-irssi
####

# download autodl-irssi community plugin
github.sh -df "github-download.zip" -dp "/tmp" -ep "/tmp/extracted" -ip "/usr/share/webapps/rutorrent/plugins/autodl-irssi" -go "autodl-community" -gr "autodl-rutorrent" -rt "source"

# download htpasswd (problems with apache-tools and openssl 1.1.x)
curly.sh -rc 6 -rw 10 -of /tmp/htpasswd.tar.gz -url "https://github.com/binhex/arch-packages/raw/master/compiled/htpasswd.tar.gz"

# extract compiled version of htpasswd
tar -xvf /tmp/htpasswd.tar.gz -C /

# config - php
####

php_ini="/etc/php/php.ini"

# configure php memory limit to improve performance
sed -i -e "s~.*memory_limit\s\=\s.*~memory_limit = 768M~g" "${php_ini}"

# configure php max execution time to try and prevent timeout issues
sed -i -e "s~.*max_execution_time\s\=\s.*~max_execution_time = 300~g" "${php_ini}"

# configure php max file uploads to prevent issues with reaching limit of upload count
sed -i -e "s~.*max_file_uploads\s\=\s.*~max_file_uploads = 200~g" "${php_ini}"

# configure php max input variables (get/post/cookies) to prevent warnings issued
sed -i -e "s~.*max_input_vars\s\=\s.*~max_input_vars = 10000~g" "${php_ini}"

# configure php upload max filesize to prevent large torrent files failing to upload
sed -i -e "s~.*upload_max_filesize\s\=\s.*~upload_max_filesize = 20M~g" "${php_ini}"

# configure php post max size (linked to upload max filesize)
sed -i -e "s~.*post_max_size\s\=\s.*~post_max_size = 25M~g" "${php_ini}"

# configure php with additional php-geoip module
sed -i -e "/.*extension=gd/a extension=geoip" "${php_ini}"

# configure php to enable sockets module (used for autodl-irssi plugin)
sed -i -e "s~.*extension=sockets~extension=sockets~g" "${php_ini}"

# configure php-fpm to use tcp/ip connection for listener
php_fpm_ini="/etc/php/php-fpm.conf"

echo "" >> "${php_fpm_ini}"
echo "; Set php-fpm to use tcp/ip connection" >> "${php_fpm_ini}"
echo "listen = 127.0.0.1:7777" >> "${php_fpm_ini}"

# configure php-fpm listener for user nobody, group users
echo "" >> "${php_fpm_ini}"
echo "; Specify user listener owner" >> "${php_fpm_ini}"
echo "listen.owner = nobody" >> "${php_fpm_ini}"
echo "" >> "${php_fpm_ini}"
echo "; Specify user listener group" >> "${php_fpm_ini}"
echo "listen.group = users" >> "${php_fpm_ini}"

# config - rutorrent
####

# define path variables
rutorrent_root_path="/usr/share/webapps/rutorrent"
rutorrent_config_path="${rutorrent_root_path}/conf"
rutorrent_plugins_path="${rutorrent_root_path}/plugins"

# remove external applications section from default config.php
# note this removes the lines between the patterns but not the
# pattern itself, as this is then used as an anchor for the 
# re-insertion of the defined section (see next block).
sed -i '/$pathToExternals = array(/,/);/{//!d}' "${rutorrent_config_path}/config.php"

# defines paths to external applications in default config.php
# this uses the pattern as an anchor point from the previous 
# command
# note the use of single quoted string to reduce escaping,
# also note the use of unicode hex char '\x27' which is a
# single quote, required as escaping a single quote in a
# single quoted string is tricky.
sed -i 's~$pathToExternals = array(.*~$pathToExternals = array(\
                "php"           => \x27/usr/bin/php\x27,              // Something like /usr/bin/php. If empty, will be found in PATH.\
                "curl"          => \x27/usr/bin/curl\x27,             // Something like /usr/bin/curl. If empty, will be found in PATH.\
                "gzip"          => \x27/usr/bin/gzip\x27,             // Something like /usr/bin/gzip. If empty, will be found in PATH.\
                "id"            => \x27/usr/bin/id\x27,               // Something like /usr/bin/id. If empty, will be found in PATH.\
                "python"        => \x27/usr/bin/python\x27,           // Something like /usr/bin/python. If empty, will be found in PATH.\
                "pgrep"         => \x27/usr/bin/pgrep\x27,            // Something like /usr/bin/pgrep. If empty, will be found in PATH.\
                "sox"           => \x27/usr/bin/sox\x27,              // Something like /usr/bin/sox. If empty, will be found in PATH.\
                "stat"          => \x27/usr/bin/stat\x27,             // Something like /usr/bin/stat. If empty, will be found in PATH.~g' "${rutorrent_config_path}/config.php"

# increase rpc timeout from 5 seconds (default) for rutorrent, as large number of torrents can mean we exceed the 5 second period
sed -i -r "s~'RPC_TIME_OUT', [0-9]+,~'RPC_TIME_OUT', 60,~g" "${rutorrent_config_path}/config.php"

# set the rutorrent autotools/autowatch plugin to 30 secs scan time, default is 300 secs
sed -i -e "s~\$autowatch_interval \= 300\;~\$autowatch_interval \= 30\;~g" "${rutorrent_plugins_path}/autotools/conf.php"

# set the rutorrent schedulder plugin to 10 mins, default is 60 mins
sed -i -e "s~\$updateInterval \= 60\;~\$updateInterval \= 10\;~g" "${rutorrent_plugins_path}/scheduler/conf.php"

# set the rutorrent diskspace plugin to point at the /data volume mapping, default is /
sed -i -e "s~\$partitionDirectory \= \&\$topDirectory\;~\$partitionDirectory \= \"/data\";~g" "${rutorrent_plugins_path}/diskspace/conf.php"

# config - autodl-irssi
####

# copy default configuration file
cp "/usr/share/webapps/rutorrent/plugins/autodl-irssi/_conf.php" "${rutorrent_plugins_path}/autodl-irssi/conf.php"

# set config for autodl-irssi plugin
sed -i -e 's~^$autodlPort.*~$autodlPort = 12345;~g' "${rutorrent_plugins_path}/autodl-irssi/conf.php"
sed -i -e 's~^$autodlPassword.*~$autodlPassword = "autodl-irssi";~g' "${rutorrent_plugins_path}/autodl-irssi/conf.php"

# set config for autodl (must match port and password specified in /usr/share/webapps/rutorrent/plugins/autodl-irssi/conf.php)
mkdir -p /home/nobody/.autodl
cat <<'EOF' > /home/nobody/.autodl/autodl.cfg.bak
[options]
gui-server-port = 12345
gui-server-password = autodl-irssi
EOF

# add in option to enable/disable autodl-irssi plugin depending on env var
# ENABLE_AUTODL_IRSSI value which is set when /home/nobody/irssi.sh runs
cat <<'EOF' >> "${rutorrent_config_path}/plugins.ini"

[autodl-irssi]
enabled = no
EOF

# create symlink to autodl script so it auto runs when irssi (irc chat client) starts
mkdir -p /home/nobody/.irssi/scripts/autorun
cd /home/nobody/.irssi/scripts
ln -s /usr/share/autodl-irssi/AutodlIrssi/ .
cd /home/nobody/.irssi/scripts/autorun
ln -s /usr/share/autodl-irssi/autodl-irssi.pl .

# container perms
####

# define comma separated list of paths 
install_paths="/usr/share/webapps,/usr/share/nginx/html,/etc/nginx,/etc/php,/run/php-fpm,/var/lib/nginx,/var/log/nginx,/etc/privoxy,/home/nobody,/usr/share/autodl-irssi"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 ${install_paths}

# create file with contents of here doc, note EOF is NOT quoted to allow us to expand current variable 'install_paths'
# we use escaping to prevent variable expansion for PUID and PGID, as we want these expanded at runtime of init.sh
cat <<EOF > /tmp/permissions_heredoc

# get previous puid/pgid (if first run then will be empty string)
previous_puid=\$(cat "/root/puid" 2>/dev/null || true)
previous_pgid=\$(cat "/root/pgid" 2>/dev/null || true)

# if first run (no puid or pgid files in /tmp) or the PUID or PGID env vars are different 
# from the previous run then re-apply chown with current PUID and PGID values.
if [[ ! -f "/root/puid" || ! -f "/root/pgid" || "\${previous_puid}" != "\${PUID}" || "\${previous_pgid}" != "\${PGID}" ]]; then

	# set permissions inside container - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
	chown -R "\${PUID}":"\${PGID}" ${install_paths}

fi

# write out current PUID and PGID to files in /root (used to compare on next run)
echo "\${PUID}" > /root/puid
echo "\${PGID}" > /root/pgid

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /usr/local/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

# check for presence of network interface docker0
check_network=$(ifconfig | grep docker0 || true)

# if network interface docker0 is present then we are running in host mode and thus must exit
if [[ ! -z "${check_network}" ]]; then
	echo "[crit] Network type detected as 'Host', this will cause major issues, please stop the container and switch back to 'Bridge' mode" | ts '%Y-%m-%d %H:%M:%.S' && exit 1
fi

export VPN_ENABLED=$(echo "${VPN_ENABLED}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VPN_ENABLED}" ]]; then
	if [ "${VPN_ENABLED}" != "no" ] && [ "${VPN_ENABLED}" != "No" ] && [ "${VPN_ENABLED}" != "NO" ]; then
		export VPN_ENABLED="yes"
		echo "[info] VPN_ENABLED defined as '${VPN_ENABLED}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		export VPN_ENABLED="no"
		echo "[info] VPN_ENABLED defined as '${VPN_ENABLED}'" | ts '%Y-%m-%d %H:%M:%.S'
		echo "[warn] !!IMPORTANT!! VPN IS SET TO DISABLED', YOU WILL NOT BE SECURE" | ts '%Y-%m-%d %H:%M:%.S'
	fi
else
	echo "[warn] VPN_ENABLED not defined,(via -e VPN_ENABLED), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
	export VPN_ENABLED="yes"
fi

if [[ $VPN_ENABLED == "yes" ]]; then

	# create directory to store openvpn config files
	mkdir -p /config/openvpn

	# set perms and owner for files in /config/openvpn directory
	set +e
	chown -R "${PUID}":"${PGID}" "/config/openvpn" &> /dev/null
	exit_code_chown=$?
	chmod -R 775 "/config/openvpn" &> /dev/null
	exit_code_chmod=$?
	set -e

	if (( ${exit_code_chown} != 0 || ${exit_code_chmod} != 0 )); then
		echo "[warn] Unable to chown/chmod /config/openvpn/, assuming SMB mountpoint" | ts '%Y-%m-%d %H:%M:%.S'
	fi

	# force removal of mac os resource fork files in ovpn folder
	rm -rf /config/openvpn/._*.ovpn

	# wildcard search for openvpn config files (match on first result)
	export VPN_CONFIG=$(find /config/openvpn -maxdepth 1 -name "*.ovpn" -print -quit)

	# if ovpn file not found in /config/openvpn then exit
	if [[ -z "${VPN_CONFIG}" ]]; then
		echo "[crit] No OpenVPN config file located in /config/openvpn/ (ovpn extension), please download from your VPN provider and then restart this container, exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	echo "[info] OpenVPN config file (ovpn extension) is located at ${VPN_CONFIG}" | ts '%Y-%m-%d %H:%M:%.S'

	# convert CRLF (windows) to LF (unix) for ovpn
	/usr/local/bin/dos2unix.sh "${VPN_CONFIG}"

	# get first matching 'remote' line in ovpn
	vpn_remote_line=$(cat "${VPN_CONFIG}" | grep -P -o -m 1 '^(\s+)?remote\s.*')

	if [ -n "${vpn_remote_line}" ]; then

		# remove all remote lines as we cannot cope with multi remote lines
		sed -i -E '/^(\s+)?remote\s.*/d' "${VPN_CONFIG}"

		# if remote line contains comments then remove
		vpn_remote_line=$(echo "${vpn_remote_line}" | sed -r 's~\s?+#.*$~~g')

		# if remote line contains old format 'tcp' then replace with newer 'tcp-client' format
		vpn_remote_line=$(echo "${vpn_remote_line}" | sed "s/tcp$/tcp-client/g")

		# write the single remote line back to the ovpn file on line 1
		sed -i -e "1i${vpn_remote_line}" "${VPN_CONFIG}"

		echo "[info] VPN remote line defined as '${vpn_remote_line}'" | ts '%Y-%m-%d %H:%M:%.S'

	else

		echo "[crit] VPN configuration file ${VPN_CONFIG} does not contain 'remote' line, showing contents of file before exit..." | ts '%Y-%m-%d %H:%M:%.S'
		cat "${VPN_CONFIG}" && exit 1

	fi

	export VPN_REMOTE=$(echo "${vpn_remote_line}" | grep -P -o -m 1 '(?<=remote\s)[^\s]+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${VPN_REMOTE}" ]]; then
		echo "[info] VPN_REMOTE defined as '${VPN_REMOTE}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] VPN_REMOTE not found in ${VPN_CONFIG}, exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	export VPN_PORT=$(echo "${vpn_remote_line}" | grep -P -o -m 1 '\d{2,5}(\s?)+(tcp|udp|tcp-client)?$' | grep -P -o -m 1 '\d+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${VPN_PORT}" ]]; then
		echo "[info] VPN_PORT defined as '${VPN_PORT}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] VPN_PORT not found in ${VPN_CONFIG}, exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	# if 'proto' is old format 'tcp' then forcibly set to newer 'tcp-client' format
	sed -i "s/^proto\stcp$/proto tcp-client/g" "${VPN_CONFIG}"

	export VPN_PROTOCOL=$(cat "${VPN_CONFIG}" | grep -P -o -m 1 '(?<=^proto\s)[^\r\n]+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${VPN_PROTOCOL}" ]]; then
		echo "[info] VPN_PROTOCOL defined as '${VPN_PROTOCOL}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		export VPN_PROTOCOL=$(echo "${vpn_remote_line}" | grep -P -o -m 1 'udp|tcp-client|tcp$' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${VPN_PROTOCOL}" ]]; then
			echo "[info] VPN_PROTOCOL defined as '${VPN_PROTOCOL}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] VPN_PROTOCOL not found in ${VPN_CONFIG}, assuming udp" | ts '%Y-%m-%d %H:%M:%.S'
			export VPN_PROTOCOL="udp"
		fi
	fi

	VPN_DEVICE_TYPE=$(cat "${VPN_CONFIG}" | grep -P -o -m 1 '(?<=^dev\s)[^\r\n\d]+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${VPN_DEVICE_TYPE}" ]]; then
		export VPN_DEVICE_TYPE="${VPN_DEVICE_TYPE}0"
		echo "[info] VPN_DEVICE_TYPE defined as '${VPN_DEVICE_TYPE}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] VPN_DEVICE_TYPE not found in ${VPN_CONFIG}, exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	# get values from env vars as defined by user
	export VPN_PROV=$(echo "${VPN_PROV}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${VPN_PROV}" ]]; then
		echo "[info] VPN_PROV defined as '${VPN_PROV}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] VPN_PROV not defined,(via -e VPN_PROV), exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	export LAN_NETWORK=$(echo "${LAN_NETWORK}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${LAN_NETWORK}" ]]; then
		echo "[info] LAN_NETWORK defined as '${LAN_NETWORK}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[crit] LAN_NETWORK not defined (via -e LAN_NETWORK), exiting..." | ts '%Y-%m-%d %H:%M:%.S' && exit 1
	fi

	export NAME_SERVERS=$(echo "${NAME_SERVERS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${NAME_SERVERS}" ]]; then
		echo "[info] NAME_SERVERS defined as '${NAME_SERVERS}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] NAME_SERVERS not defined (via -e NAME_SERVERS), defaulting to name servers defined in readme.md" | ts '%Y-%m-%d %H:%M:%.S'
		export NAME_SERVERS="209.222.18.222,84.200.69.80,37.235.1.174,1.1.1.1,209.222.18.218,37.235.1.177,84.200.70.40,1.0.0.1"
	fi

	if [[ $VPN_PROV != "airvpn" ]]; then
		export VPN_USER=$(echo "${VPN_USER}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${VPN_USER}" ]]; then
			echo "[info] VPN_USER defined as '${VPN_USER}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] VPN_USER not defined (via -e VPN_USER), assuming authentication via other method" | ts '%Y-%m-%d %H:%M:%.S'
		fi

		export VPN_PASS=$(echo "${VPN_PASS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${VPN_PASS}" ]]; then
			echo "[info] VPN_PASS defined as '${VPN_PASS}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] VPN_PASS not defined (via -e VPN_PASS), assuming authentication via other method" | ts '%Y-%m-%d %H:%M:%.S'
		fi
	fi

	export VPN_OPTIONS=$(echo "${VPN_OPTIONS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${VPN_OPTIONS}" ]]; then
		echo "[info] VPN_OPTIONS defined as '${VPN_OPTIONS}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[info] VPN_OPTIONS not defined (via -e VPN_OPTIONS)" | ts '%Y-%m-%d %H:%M:%.S'
		export VPN_OPTIONS=""
	fi

	if [[ $VPN_PROV == "pia" ]]; then

		export STRICT_PORT_FORWARD=$(echo "${STRICT_PORT_FORWARD}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${STRICT_PORT_FORWARD}" ]]; then
			echo "[info] STRICT_PORT_FORWARD defined as '${STRICT_PORT_FORWARD}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] STRICT_PORT_FORWARD not defined (via -e STRICT_PORT_FORWARD), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
			export STRICT_PORT_FORWARD="yes"
		fi

	fi

	export ENABLE_PRIVOXY=$(echo "${ENABLE_PRIVOXY}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${ENABLE_PRIVOXY}" ]]; then
		echo "[info] ENABLE_PRIVOXY defined as '${ENABLE_PRIVOXY}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] ENABLE_PRIVOXY not defined (via -e ENABLE_PRIVOXY), defaulting to 'no'" | ts '%Y-%m-%d %H:%M:%.S'
		export ENABLE_PRIVOXY="no"
	fi

fi

export ENABLE_AUTODL_IRSSI=$(echo "${ENABLE_AUTODL_IRSSI}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${ENABLE_AUTODL_IRSSI}" ]]; then
	echo "[info] ENABLE_AUTODL_IRSSI defined as '${ENABLE_AUTODL_IRSSI}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] ENABLE_AUTODL_IRSSI not defined (via -e ENABLE_AUTODL_IRSSI), defaulting to 'no'" | ts '%Y-%m-%d %H:%M:%.S'
	export ENABLE_AUTODL_IRSSI="no"
fi

export ENABLE_RPC2=$(echo "${ENABLE_RPC2}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${ENABLE_RPC2}" ]]; then
	echo "[info] ENABLE_RPC2 defined as '${ENABLE_RPC2}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] ENABLE_RPC2 not defined (via -e ENABLE_RPC2), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
	export ENABLE_RPC2="yes"
fi

if [[ $ENABLE_RPC2 == "yes" ]]; then
	export ENABLE_RPC2_AUTH=$(echo "${ENABLE_RPC2_AUTH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${ENABLE_RPC2_AUTH}" ]]; then
		echo "[info] ENABLE_RPC2_AUTH defined as '${ENABLE_RPC2_AUTH}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] ENABLE_RPC2_AUTH not defined (via -e ENABLE_RPC2_AUTH), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
		export ENABLE_RPC2_AUTH="yes"
	fi

	if [[ $ENABLE_RPC2_AUTH == "yes" ]]; then
		export RPC2_USER=$(echo "${RPC2_USER}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${RPC2_USER}" ]]; then
			echo "[info] RPC2_USER defined as '${RPC2_USER}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] RPC2_USER not defined (via -e RPC2_USER), defaulting to 'admin'" | ts '%Y-%m-%d %H:%M:%.S'
			export RPC2_USER="admin"
		fi

		export RPC2_PASS=$(echo "${RPC2_PASS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${RPC2_PASS}" ]]; then
			echo "[info] RPC2_PASS defined as '${RPC2_PASS}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] RPC2_PASS not defined (via -e RPC2_PASS), defaulting to 'rutorrent'" | ts '%Y-%m-%d %H:%M:%.S'
			export RPC2_PASS="rutorrent"
		fi
	fi
fi

export ENABLE_WEBUI_AUTH=$(echo "${ENABLE_WEBUI_AUTH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${ENABLE_WEBUI_AUTH}" ]]; then
	echo "[info] ENABLE_WEBUI_AUTH defined as '${ENABLE_WEBUI_AUTH}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] ENABLE_WEBUI_AUTH not defined (via -e ENABLE_WEBUI_AUTH), defaulting to 'yes'" | ts '%Y-%m-%d %H:%M:%.S'
	export ENABLE_WEBUI_AUTH="yes"
fi

if [[ $ENABLE_WEBUI_AUTH == "yes" ]]; then
	export WEBUI_USER=$(echo "${WEBUI_USER}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${WEBUI_USER}" ]]; then
		echo "[info] WEBUI_USER defined as '${WEBUI_USER}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] WEBUI_USER not defined (via -e WEBUI_USER), defaulting to 'admin'" | ts '%Y-%m-%d %H:%M:%.S'
		export WEBUI_USER="admin"
	fi

	export WEBUI_PASS=$(echo "${WEBUI_PASS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${WEBUI_PASS}" ]]; then
		echo "[info] WEBUI_PASS defined as '${WEBUI_PASS}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] WEBUI_PASS not defined (via -e WEBUI_PASS), defaulting to 'rutorrent'" | ts '%Y-%m-%d %H:%M:%.S'
		export WEBUI_PASS="rutorrent"
	fi
fi

export APPLICATION="rtorrent"

EOF

# replace env vars placeholder string with contents of file (here doc)
sed -i '/# ENVVARS_PLACEHOLDER/{
    s/# ENVVARS_PLACEHOLDER//g
    r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

# cleanup
cleanup.sh
