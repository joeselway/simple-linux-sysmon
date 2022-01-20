#!/bin/bash

########### Simple Linux System Monitoring tool ############
#                                                          #
# By github.com/joeselway                                  #
#                                                          #
# Known issues:                                            #
#                                                          #
# - Output will accumulate if log collector not working    #
# - Doesn't handle multiple default gateways (to-do)       #
# - Network utilization to-do                              #
#                                                          #
############################################################

########## CONFIGURATION ##############

# Set master log directory
logDir="/var/log"

# Optionally set a log sub directory, or "" to log to above
logSubDir="pretendco"

# Set log file name
logFileName="sysmonitor.log"

# Enable debug echo?
debugEchoEnabled=true

# Use net-tools instead of iproute2?
netToolsEnabled=true

#######################################

##### Main: ###########################

main() {
	getHostInfo
	getCpuStats
	getMemStats
	getNetInfo
	#getNetStats

	jsonOut=$(echo \
	"{"\
	"\"hostname\":\"$hostname\","\
	"\"time\":\"$(timestamp)\","\
	"\"stats\":["\
	"{\"group\":\"cpu\",\"load1min\":\"$load1m\",\"load5min\":\"$load5m\",\"load15min\":\"$load15m\",\"time_user\":\"$timeUser\",\"time_system\":\"$timeSys\",\"time_idle\":\"$timeIdle\",\"time_waiting\":\"$timeWait\",\"time_stolen\":\"$timeStolen\",\"time_utilized\":\"$timeUtilized\"},"\
	"{\"group\":\"memory\",\"memory_total\":\"$memTotal\",\"memory_free\":\"$memFree\",\"memory_available\":\"$memAvailable\",\"memory_committed\",\"$memCommitted\"},"\
	"{\"group\":\"network_info\",\"default_gateway\":\"$defaultGateway\",\"interface\":\"$dgif\",\"local_ip\":\"$dgifIP\",\"public_ip\":\"$publicIP\"}"\
	"]}")\

	if [ "$debugEchoEnabled" = true ]; then debugEcho; fi
	outputJson
}

##### Host info: ######################

# Define a timestamp
timestamp() {
	date +"%Y-%m-%d %H:%M:%S (%s)"
}

getHostInfo() {
# Get curent hostname
	hostname=$(hostname)
}
#######################################

##### CPU & Memory stats: #############

getCpuStats() {
	# Get CPU stats from /proc/loadavg
	loadAvg=$(cat /proc/loadavg)
	load1m=${loadAvg:0:4}
	load5m=${loadAvg:5:4}
	load15m=${loadAvg:10:4}

	# Get more CPU stats from vmstat

	vmstatString=$(vmstat | tail -1 | xargs)
	timeUser=$(echo "$vmstatString" | cut -d " " -f 13)
	timeSys=$(echo "$vmstatString" | cut -d " " -f 14)
	timeIdle=$(echo "$vmstatString" | cut -d " " -f 15)
	timeWait=$(echo "$vmstatString" | cut -d " " -f 16)
	timeStolen=$(echo "$vmstatString" | cut -d " " -f 17)

	# Calculate total utilization

	timeUtilized=$((timeUser + timeSys + timeStolen))
}

# NOTE: Using MemAvailable from /proc/meminfo per README.md
# Diff this with total to get "MemCommitted" value for same reason

# Get memory stats from /proc/meminfo

getMemStats() {
	memTotal=$(sed "1q;d" /proc/meminfo | xargs | cut -d " " -f 2)
	memFree=$(sed "2q;d" /proc/meminfo | xargs | cut -d " " -f 2)
	memAvailable=$(sed "3q;d" /proc/meminfo | xargs | cut -d " " -f 2)
	memCommitted=$((memTotal - memAvailable))
}

#######################################

##### Network info: ###################



getNetInfo() {
	if [ "$netToolsEnabled" = true ]; then
		# Get default gateway from route list, then get associated interface name/IP
		### Using net-tools###
		if [ "$debugEchoEnabled" = true ]; then echo "Using net-tools for network info..."; fi
		defaultGateway=$(route -n | grep "^0.0.0.0" | xargs | cut -d " " -f 2)
		dgif=$(route -n | grep "^0.0.0.0" | xargs | cut -d " " -f 8)
		dgifIP=$(ifconfig enp0s5 | grep netmask | xargs | cut -d " " -f 2)
	else
		# Get default gateway from route list, then get associated interface name/IP
		### Using iproute2###
		if [ "$debugEchoEnabled" = true ]; then echo "Using iproute2 for network info..."; fi
		ipString=$(ip route get 8.8.8.8 | grep src)
		defaultGateway=$(echo "$ipString" | cut -d " " -f 3)
		dgif=$(echo "$ipString" | cut -d " " -f 5)
		dgifIP=$(echo "$ipString" | cut -d " " -f 7)
	fi

	# If network connection exists, try to get public IP from OpenDNS
	if [ -n $defaultGateway ] && [ -n $dgifIP ]; then
		publicIP=$(dig @resolver1.opendns.com myip.opendns.com +short)
	fi

	# Set any missing network info to N/A
	if [ -z "$defaultGateway" ]; then defaultGateway="N/A"; fi
	if [ -z "$dgif" ]; then dgif="N/A"; fi
	if [ -z "$dgifIP" ]; then dgifIP="N/A"; fi
	if [ -z "$publicIP" ]; then publicIP="N/A"; fi
}
#######################################

# JSONify


#####  ECHO FOR DEBUG #################

debugEcho() {
	echo $(timestamp)
	echo "** CPU 1/5/15 min average: **"
	echo "$load1m"
	echo "$load5m"
	echo "$load15m"
	echo "** CPU time: **"
	echo "$timeUser"
	echo "$timeSys"
	echo "$timeIdle"
	echo "$timeWait"
	echo "$timeStolen"
	echo "$timeUtilized"
	echo "** Network info: **"
	echo "$defaultGateway"
	echo "$dgif"
	echo "$dgifIP"
	echo "$publicIP"
	echo "** Memory stats: **"
	echo "$memAvailable"
	echo "$memCommitted"
	echo "$jsonOut"
}

#######################################

##### Output: #########################

# Warn if cannot write to /var/log and fall back to $HOME
outputJson() {
if [ ! -w "$logDir" ] && [ ! -w "$logDir"/"$logSubDir" ]; then
	echo "WARNING: Cannot write to /var/log/, logging to $HOME"
	logDir=$HOME
fi
if [ ! -d "$logDir"/"$logSubDir" ]; then mkdir $logDir/$logSubDir; fi
echo "$jsonOut" >> $logDir/$logSubDir/$logFileName
}

########################################

##### Main: ############################

main

########################################
