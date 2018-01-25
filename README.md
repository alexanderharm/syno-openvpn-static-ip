# SynoOpenVpnStaticIp

This script sets up static client IPs when using OpenVPN of `VPN Server` package.

#### 1. Notes

- Pass the client list like this: "<username>:<ipsuffix>" (e. g. "john:202" will make sure that user "john" will be assigned IP "10.8.0.202")
- Use IP-suffixes great enough in order not to conflict with the build in dynamic assignment
- The script will automatically update itself using `git`.

#### 2. Installation:

- install the package `Git Server` on your Synology NAS
- create a shared folder called e. g. `sysadmin` (you want to restrict access to administrators and hide it in the network)
- connect via `ssh` to the NAS and execute the following commands

```bash
# navigate to the shared folder
cd /volume1/sysadmin
# clone the following repo
git clone https://github.com/alexanderharm/syno-openvpn-static-ip
```

- create two tasks in the `Task Scheduler`

```
# Type
Scheduled task > User-defined script

# General
Task:    SynoOpenVpnStaticIp
User:    root
Enabled: yes

# Schedule
Run on the following days: Daily
First run time:            (00:00 or the full hour after the replication jobs start)
Frequency:                 Every 1 hour(s)
Last run time:				23:45

# Task Settings
User-defined script: /volume1/sysadmin/syno-openvpn-static-ip/synoOpenVpnStaticIp.sh "<username1>:<ipsuffix1>" "<username2>:<ipsuffix2>"
```

```
# Type
Scheduled task > User-defined script

# General
Task:    SynoOpenVpnStaticIpBoot
User:    root
Enabled: yes

# Schedule
Run on the following days: Daily
First run time:            (00:00 or the full hour after the replication jobs start)
Frequency:                 Every 1 hour(s)
Last run time:				23:45

# Task Settings
User-defined script: /volume1/sysadmin/syno-openvpn-static-ip/synoOpenVpnStaticIp.sh "<username1>:<ipsuffix1>" "<username2>:<ipsuffix2>"
```
