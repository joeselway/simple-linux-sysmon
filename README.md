# simple-linux-sysmon
A simple Linux system monitoring tool, written in bash for maximum portability.

⚠️ **This tool has been created for academic purposes only (bash practice) and should not be used in production!!** ⚠️

**Overview**

Logs basic system info and performance statistics to a local test file, in JSON format, for collection by a compatible log forwarder

**System Requirements:**
- Ubuntu
  - 20.04 (tested)
  - 18.04 (tested)
  - 16.04 (?? untested)

** Installation **

- Copy sysmon.sh to /usr/local/pretendco/bin/ or desired location (if changing, modify sysmonitor.service accordingly)
- Copy sysmonitor.server and sysmonitor.timer to /etc/systemd/system/
- Set sane permissions
- Run `systemctl enable sysmonitor.timer`

** Known issues **

- Output will accumulate if log collector not working.
- Doesn't handle multiple interface gateways.
- Network utilization for primary (top default gateway) interface only.

**Data collected:**
- CPU utilization
  - 1/5/15 minute load average
  - Current cpu time %age breakdown
- Memory utilization:
  - Total memory
  - Free memory (probably useless per below)
  - Available memory (see https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=34e431b0ae398fc54ea69ff85ec700722c9da773)
  - Committed memory (Total less Available)
- Network info
  - Default route gateway IP (this is used to determine primary network interface)
  - Interface name
  - IPv4 Address
  - Public IP address from OpenDNS (if local gateway can be found)
- Network utilization:
  - Total bytes tx/rx for primary interface
  - 1 second sample for tx/rx bytes per second calculation
