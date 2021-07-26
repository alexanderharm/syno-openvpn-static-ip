#!/bin/bash

# check if run as root
if [ $(id -u "$(whoami)") -ne 0 ]; then
	echo "SynoOpenVpnStaticIp needs to run as root!"
	exit 1
fi

# check if git is available
if command -v /usr/bin/git > /dev/null; then
	git="/usr/bin/git"
elif command -v /usr/local/git/bin/git > /dev/null; then
	git="/usr/local/git/bin/git"
elif command -v /opt/bin/git > /dev/null; then
	git="/opt/bin/git"
else
	echo "Git not found therefore no autoupdate. Please install the official package \"Git Server\", SynoCommunity's \"git\" or Entware-ng's."
	git=""
fi

# save today's date
today=$(date +'%Y-%m-%d')

# check for arguments
if [ $# -eq 0 ]; then
	echo "No clients passed as arguments to SynoOpenVpnStaticIp!"
	exit 1
else
	echo "The following clients where passed: $*."
	clients=( "$@" )
fi

# self update run once daily
if [ ! -z "${git}" ] && [ -d "$(dirname "$0")/.git" ] && [ -f "$(dirname "$0")/autoupdate" ]; then
	if [ ! -f /tmp/.synoOpenVpnStaticIpUpdate ] || [ "${today}" != "$(date -r /tmp/.synoOpenVpnStaticIpUpdate +'%Y-%m-%d')" ]; then
		echo "Checking for updates..."
		# touch file to indicate update has run once
		touch /tmp/.synoOpenVpnStaticIpUpdate
		# change dir and update via git
		cd "$(dirname "$0")" || exit 1
		$git fetch
		commits=$($git rev-list HEAD...origin/master --count)
		if [ $commits -gt 0 ]; then
			echo "Found a new version, updating..."
			$git pull --force
			echo "Executing new version..."``
			exec "$(pwd -P)/synoOpenVpnStaticIp.sh" "$@"
			# In case executing new fails
			echo "Executing new version failed."
			exit 1
		fi
		echo "No updates available."
	else
		echo "Already checked for updates today."
	fi
fi

# Save if service restart is needed
serviceRestart=0

# Check if client config dir exists
if [ ! -d "/var/packages/VPNCenter/etc/openvpn/ccd" ]; then
    mkdir -p /var/packages/VPNCenter/etc/openvpn/ccd
	echo "Created client config dir."
else
	echo "Client config dir exists."
fi

# Add to config
if ! grep -q "client-config-dir ccd" "/var/packages/VPNCenter/etc/openvpn/openvpn.conf"; then
	echo "client-config-dir ccd" >> "/var/packages/VPNCenter/etc/openvpn/openvpn.conf"
	echo "Config modified."
	((serviceRestart++))
else
	echo "Config untouched."
fi

# Get server IP range
ipRange="$(grep -Eo '^server [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.' /var/packages/VPNCenter/etc/openvpn/openvpn.conf | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.')"
echo "IP range is: \"${ipRange}\""
ipMin="$(grep -Eo '^max-clients [0-9]+' /var/packages/VPNCenter/etc/openvpn/openvpn.conf | grep -Eo '[0-9]+')"
ipMin=$((2 + ipMin * 4))

# Check client configs
for (( i=0; i<${#clients[@]}; i++ )); do

    username="$(echo ${clients[$i]} | cut -d ':' -f 1)"
    ipLocal="$(echo ${clients[$i]} | cut -d ':' -f 2)"
    ipRemote="$((ipLocal-1))"

	# Check for even numbers
	if [ $((ipLocal % 2)) -ne 0 ]; then
		echo "IP \"${ipLocal}\" of user \"${username}\" not even. Skipping."
		continue
	fi

	# Check for high enough IP
	if [ $ipLocal -le $ipMin ]; then
		echo "IP \"${ipLocal}\" of user \"${username}\" too low. Skipping."
		continue
	fi

    # Check if config exists or verify
    if [ ! -f "/var/packages/VPNCenter/etc/openvpn/ccd/${username}" ]; then
		echo "ifconfig-push ${ipRange}${ipLocal} ${ipRange}${ipRemote}" > "/var/packages/VPNCenter/etc/openvpn/ccd/${username}"
		echo "Added IP \"${ipLocal}\" for user \"${username}\"."
		((serviceRestart++))
    elif ! grep -Eq "ifconfig-push ${ipRange}${ipLocal} ${ipRange}${ipRemote}" "/var/packages/VPNCenter/etc/openvpn/ccd/${username}"; then
		echo "ifconfig-push ${ipRange}${ipLocal} ${ipRange}${ipRemote}" > "/var/packages/VPNCenter/etc/openvpn/ccd/${username}"
		echo "Modified user \"${username}\" to IP \"${ipLocal}\"."
		((serviceRestart++))
	else
		echo "User \"${username}\" is OK."
	fi
done

# Prevent config from being overwritten
if grep -q 'overwriteccfiles=true' /var/packages/VPNCenter/target/etc/openvpn/radiusplugin.cnf; then
	echo "Modified RADIUS config."
else
	echo "RADIUS config untouched."
fi
sed -i "s:overwriteccfiles=true:overwriteccfiles=false:g" /var/packages/VPNCenter/target/etc/openvpn/radiusplugin.cnf


# Restart service if needed
if [ $serviceRestart -gt 0 ]; then
	if ! synoservice --restart pkgctl-VPNCenter; then 
		/var/packages/VPNCenter/target/scripts/openvpn.sh restart
	fi
	echo "Restarted VPN service."
fi

exit 0