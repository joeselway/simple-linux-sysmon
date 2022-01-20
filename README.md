# simple-linux-sysmon
A simple Linux system monitoring tool, written in bash for maximum portability

**This tool has been created for academic purposes only (bash practice) and should not be used in production!!**

System Requirements:
- Ubuntu
  - 20.04 (tested)
  - 18.04 (??)
  - 16.04 (??)

Data collected:
- CPU utilization
  - 1/5/15 minute load average
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
  - COMING SOON!
