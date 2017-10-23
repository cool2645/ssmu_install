#!/bin/bash

apt-get update && apt-get install ipset
ipset -N china hash:net
wget http://www.ipdeny.com/ipblocks/data/countries/cn.zone
for i in $(cat cn.zone ); do ipset -A china $i; done
iptables -A OUTPUT -p tcp -m set --match-set china dst -m state --state NEW -j DROP
iptables -A OUTPUT -p udp -m set --match-set china dst -m state --state NEW -j DROP
