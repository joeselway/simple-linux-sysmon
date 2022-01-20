#!/bin/bash

loadAvg=$(cat /proc/loadavg)
avg1m=${loadAvg:0:4}
avg5m=${loadAvg:5:4}
avg15m=${loadAvg:10:4}

hostname=$(hostname)
defaultGateway=$(route -n | grep "^0.0.0.0" | xargs | cut -d " " -f 2)
dgif=$(route -n | grep "^0.0.0.0" | xargs | cut -d " " -f 8)
dgifIP=$(ifconfig enp0s5 | grep netmask | xargs | cut -d " " -f 2)
if [ -n $defaultGateway ] && [ -n $dgifIP ]; then
echo blah #	publicIP=$(dig @resolver1.opendns.com myip.opendns.com +short)
fi

if [ -z $defaultGateway ]; then defaultGateway="N/A"; fi
if [ -z $dgif ]; then dgif="N/A"; fi
if [ -z $dgifIP ]; then dgifIP="N/A"; fi
if [ -z $publicIP ]; then publicIP="N/A"; fi

timestamp() {
	date +"%Y-%m-%d %H:%M:%S (%s)"
}

echo $(timestamp)
echo "$loadAvg"
echo "$avg1m"
echo "$avg5m"
echo "$avg15m"
echo "$defaultGateway"
echo "$dgif"
echo "$dgifIP"
echo "$publicIP"

echo \
"{\"hostname\":\"$hostname\","\
"\"time\":\"$(timestamp)\","\
"\"stats\":["\
"{\"group\":\"cpu\",\"avg1min\":\"$avg1m\",\"avg5min\":\"$avg5m\",\"avg15min\":\"$avg15m\"},"\
"{\"group\":\"network\",\"default_gateway\":\"$defaultGateway\",\"interface\":\"$dgif\",\"local_ip\":\"$dgifip\",\"public_ip\":\"$publicIP\"}]}"

exit 0

