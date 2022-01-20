#!/bin/bash

########### Simple Linux System Monitoring tool ############
#                                                          #
# By github.com/joeselway                                  #
#                                                          #
# Known issues:                                            #
#                                                          #
# - Output will accumulate if log collector not working    #
# - Doesn't handle multiple default gateways (to-do)       #
# - Memory utilization to-do				               #
# - Network utilization to-do                              #
# - Output to file to-do                                   #
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
debugEcho=$TRUE

#######################################

##### Host info: ######################

# Define a timestamp
timestamp() {
	date +"%Y-%m-%d %H:%M:%S (%s)"
}

# Get curent hostname
hostname=$(hostname)

#######################################

##### CPU & Memory stats: #############

# Get CPU stats from /proc/loadavg
loadAvg=$(cat /proc/loadavg)
avg1m=${loadAvg:0:4}
avg5m=${loadAvg:5:4}
avg15m=${loadAvg:10:4}

# NOTE: Using MemAvailable from /proc/meminfo per README.md
# Diff this with total to get "MemCommitted" value for same reason

# Get memory stats from /proc/meminfo


memTotal=$(sed "1q;d" /proc/meminfo | xargs | cut -d " " -f 2)
memFree=$(sed "2q;d" /proc/meminfo | xargs | cut -d " " -f 2)
memAvailable=$(sed "3q;d" /proc/meminfo | xargs | cut -d " " -f 2)
memCommitted=$((memTotal - memAvailable))

#######################################

##### Network info: ###################

# Get default gateway from route list, then get associated interface name/IP
defaultGateway=$(route -n | grep "^0.0.0.0" | xargs | cut -d " " -f 2)
dgif=$(route -n | grep "^0.0.0.0" | xargs | cut -d " " -f 8)
dgifIP=$(ifconfig enp0s5 | grep netmask | xargs | cut -d " " -f 2)

# If network connection exists, try to get public IP from OpenDNS
if [ -n $defaultGateway ] && [ -n $dgifIP ]; then
    publicIP=$(dig @resolver1.opendns.com myip.opendns.com +short)
fi

# Set any missing network info to N/A
if [ -z $defaultGateway ]; then defaultGateway="N/A"; fi
if [ -z $dgif ]; then dgif="N/A"; fi
if [ -z $dgifIP ]; then dgifIP="N/A"; fi
if [ -z $publicIP ]; then publicIP="N/A"; fi

#######################################

#####  ECHO FOR DEBUG #################

echo $(timestamp)
#echo "$loadAvg"
echo "$avg1m"
echo "$avg5m"
echo "$avg15m"
echo "$defaultGateway"
echo "$dgif"
echo "$dgifIP"
echo "$publicIP"
echo "$memAvailable"
echo "$memCommitted"

jsonOut=$(echo \
"{"\
"\"hostname\":\"$hostname\","\
"\"time\":\"$(timestamp)\","\
"\"stats\":["\
"{\"group\":\"cpu\",\"avg1min\":\"$avg1m\",\"avg5min\":\"$avg5m\",\"avg15min\":\"$avg15m\"},"\
"{\"group\":\"memory\",\"memory_total\":\"$memTotal\",\"memory_free\":\"$memFree\",\"memory_available\":\"$memAvailable\",\"memory_committed\",\"$memCommitted\"},"\
"{\"group\":\"network_info\",\"default_gateway\":\"$defaultGateway\",\"interface\":\"$dgif\",\"local_ip\":\"$dgifIP\",\"public_ip\":\"$publicIP\"}"\
"]}")\

#######################################

##### Output and exit: ################

# Warn if cannot write to /var/log and fall back to $HOME
if [ ! -w $logDir ] && [ ! -w $logDir/$logSubDir ]; then
	echo "WARNING: Cannot write to /var/log/, logging to $HOME"
	logDir=$HOME
fi
if [ ! -d $logDir/$logSubDir ]; then mkdir $logDir/$logSubDir; fi
echo "$jsonOut" >> $logDir/$logSubDir/$logFileName

exit 0

#######################################
