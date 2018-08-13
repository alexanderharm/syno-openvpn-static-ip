# SynoOpenVpnStaticIp

This script sets up static client IPs when using OpenVPN of `VPN Server` package.

#### 1. Notes

- Pass the client list like this: `"<username>:<ipsuffix>"` (e. g. `"john:202"` will make sure that user `john` will be assigned IP `10.8.0.202`)
- Please follow Synology/OpenVPN convention and only assign even numbers greater than: `2 + 4 * <max-clients>`
- Use IP-suffixes great enough in order not to conflict with the build in dynamic assignment
- The script is able to automatically update itself using `git`.

#### 2. Installation

##### 2.1 Install Git (optional)

- install the package `Git Server` on your Synology NAS, make sure it is running (requires sometimes extra action in `Package Center` and `SSH` running)
- alternatively add SynoCommunity to `Package Center` and install the `Git` package ([https://synocommunity.com/](https://synocommunity.com/#easy-install))
- you can also use `entware-ng` (<https://github.com/Entware/Entware-ng>)

##### 2.2 Install this script (using git)

- create a shared folder e. g. `sysadmin` (you want to restrict access to administrators and hide it in the network)
- connect via `ssh` to the NAS and execute the following commands

```bash
# navigate to the shared folder
cd /volume1/sysadmin
# clone the following repo
git clone https://github.com/alexanderharm/syno-openvpn-static-ip
# to enable autoupdate
touch syno-openvpn-static-ip/autoupdate
```

##### 2.3 Install this script (manually)

- create a shared folder e. g. `sysadmin` (you want to restrict access to administrators and hide it in the network)
- copy your `synoOpenVpnStaticIp.sh` to `sysadmin` using e. g. `File Station` or `scp`
- make the script executable by connecting via `ssh` to the NAS and executing the following command

```bash
chmod 755 /volume1/syno-openvpn-static-ip/synoOpenVpnStaticIp.sh
```

#### 3. Setup

- run script manually (as root)

```bash
/volume1/sysadmin/syno-openvpn-static-ip/synoOpenVpnStaticIp.sh "<username1>:<ipsuffix1>" "<username2>:<ipsuffix2>"
```

*AND/OR*

- create a task in the `Task Scheduler` via WebGUI

```
# Type
Scheduled task > User-defined script

# General
Task:    SynoOpenVpnStaticIp
User:    root
Enabled: yes

# Schedule
Run on the following days: Daily
First run time:            00:00
Frequency:                 Every 1 hour(s)
Last run time:			   23:00

# Task Settings
User-defined script: /volume1/sysadmin/syno-openvpn-static-ip/synoOpenVpnStaticIp.sh "<username1>:<ipsuffix1>" "<username2>:<ipsuffix2>"
```

#### 4. Example

```bash
/volume1/sysadmin/syno-openvpn-static-ip/synoOpenVpnStaticIp.sh "extbackup:202"
```