#!/bin/bash

#
# Example router activation script
#
# 1/ Remove default route through peer
# 2/ Take active router address
# 3/ Activate PPP link
# 4/ Wait for a few seconds
#

ip route del default via 192.168.1.1 dev eth0
ip addr add 192.168.1.1/24 dev eth0
ifup ppp0
sleep 10
