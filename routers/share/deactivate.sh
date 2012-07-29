#!/bin/bash

#
# Example router de-activation script
#
# 1/ Kill internet link
# 2/ Nuke them from orbit, it's the only way to be sure
# 3/ Release main router address
# 4/ Add default route through peer
#

ifdown --force ppp0
sleep 2
killall -9 pppd
sleep 2

ip addr del 192.168.1.1 dev eth0
ip route add default via 192.168.1.1 dev eth0
