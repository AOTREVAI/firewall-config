#!/bin/bash

# VARIABILI
IPT="/usr/sbin/iptables"

# RESET
$IPT -F # cancella la tabella specificata, se nessuna specificata cancella tabella "filter"
$IPT -t nat -F
$IPT -Z
$IPT -X

# IMPOSTA DEFAULT POLICY
$IPT -P INPUT DROP 
$IPT -P FORWARD DROP
$IPT -P OUTPUT ACCEPT#!/bin/bash


# Kernel setup, abilita il forwarding a livello di kernel
echo 1 > /proc/sys/net/ipv4/ip_forward

# Local accept
$IPT -A INPUT -i lo -j ACCEPT

# CHAIN AGGIUNTIVE
$IPT -N LAN-DMZ
$IPT -N DMZ-LAN
$IPT -N LAN-PUB
$IPT -N PUB-LAN
$IPT -N DMZ-PUB
$IPT -N PUB-DMZ 

$IPT -A FORWARD -i enp0s8 -o enp0s9 -j LAN-DMZ
$IPT -A FORWARD -i enp0s9 -o enp0s8 -j DMZ-LAN
$IPT -A FORWARD -i enp0s8 -o enp0s3 -j LAN-PUB
$IPT -A FORWARD -i enp0s3 -o enp0s8 -j PUB-LAN
$IPT -A FORWARD -i enp0s9 -o enp0s3 -j DMZ-PUB
$IPT -A FORWARD -i enp0s3 -o enp0s9 -j PUB-DMZ
# SNAT
$IPT -t nat -A POSTROUTING -O enp0s3 -s 192.168.10.0/24 -j SNAT --to-source 172.22.202.10

# INPUT
# aprire porta per ssh su (i)nterfaccia (s)ource (p)rotocol portadestinazione
$IPT -A INPUT -i enp0s3 -s 172.22.202.102 -p tcp --dport 2222 -j ACCEPT  

# apre la porta per connessioni iniziate da noi e ancora attive
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# abilita il ping
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT


# FORWARD
# $IPT -A FORWARD -i enp0s8 -o enp0s3 -s 192.168.10.0/24 -p icmp --icmp-type 8 -j ACCEPT
#
# $IPT -A FORWARD -i enp0s3 -o enp0s8 -s 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
#
# $IPT -A FORWARD -i enp0s8 -o enp0s9 -s 192.168.10.0/24 -d 10.10.10.0/24 -p icmp --icmp-type 8 -j ACCEPT
#
# $IPT -A FORWARD -i enp0s9 -o enp0s8 -s 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

#LAN-PUB
$IPT -A LAN-PUB -s 192.168.10.0/24 -i icmp --icmp-type 8 -j ACCEPT
$IPT -A LAN-PUB -s 192.168.10.0/24 -i -p tcp --dport 80 -j ACCEPT
$IPT -A LAN-PUB -s 192.168.10.0/24 -i -p tcp --dport 443 -j ACCEPT
$IPT -A LAN-PUB -s 192.168.10.0/24 -i -p udp --dport 53 -j ACCEPT

#PUB-LAN 
$IPT -A PUB-LAN -d 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

#LAN-DMZ
$IPT -A LAN-DMZ -s 192.168.10.0/24 -d 10.10.10.0/24 -p icmp --icmp-type 8 -j ACCEPT

#DMZ-LAN
$IPT -A DMZ-LAN -s 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

