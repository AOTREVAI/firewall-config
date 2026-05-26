#!/bin/bash

# VARIABILI
IPT="/usr/sbin/iptables"

# RESET
$IPT -F # cancella la tabella specificata, se nessuna specificata cancella tabella "filter"
$IPT -t nat -F
$IPT -t raw -F
$IPT -Z
$IPT -X

# IMPOSTA DEFAULT POLICY
$IPT -P INPUT DROP 
$IPT -P FORWARD DROP
$IPT -P OUTPUT ACCEPT


# Kernel setup, abilita il forwarding a livello di kernel e configurazioni per ftp
echo 1 > /proc/sys/net/ipv4/ip_forward
/sbin/modprobe nf_nat_ftp
/sbin/modprobe nf_conntrack_ftp
# abilita il modulo ftp in ascolto SOLO sulla porta 21
$IPT -t raw -A PREROUTING -p tcp --dport 21 -j CT --helper ftp

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
$IPT -t nat -A POSTROUTING -o enp0s3 -s 192.168.14.0/24 -j SNAT --to-source 172.22.202.14
$IPT -t nat -A POSTROUTING -o enp0s3 -s 10.10.14.0/24 -j SNAT --to-source 172.22.202.14

# DNAT 
$IPT -t nat -A PREROUTING -i enp0s3 -d 172.22.202.14 -p tcp -m multiport --dports 80,443 -j DNAT --to-destination 10.10.14.10

# INPUT
# aprire porta per ssh su (i)nterfacci/a (s)ource (p)rotocol portadestinazione
$IPT -A INPUT -i enp0s3 -s 172.22.202.119 -p tcp --dport 2222 -j ACCEPT # dipende da indirizzo ip host per ssh 
# abilita il ping con un rate limiting 
$IPT -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 1 -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type echo-request -j DROP
# apre la porta per connessioni iniziate da noi e ancora attive
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# FORWARD
# $IPT -A FORWARD -i enp0s8 -o enp0s3 -s 192.168.10.0/24 -p icmp --icmp-type 8 -j ACCEPT
# $IPT -A FORWARD -i enp0s3 -o enp0s8 -s 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
# $IPT -A FORWARD -i enp0s8 -o enp0s9 -s 192.168.10.0/24 -d 10.10.10.0/24 -p icmp --icmp-type 8 -j ACCEPT
# $IPT -A FORWARD -i enp0s9 -o enp0s8 -s 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

#LAN-PUB
$IPT -A LAN-PUB -s 192.168.14.0/24 -p icmp --icmp-type 8 -j ACCEPT
$IPT -A LAN-PUB -s 192.168.14.0/24 -p tcp --dport 80 -j ACCEPT
$IPT -A LAN-PUB -s 192.168.14.0/24 -p tcp --dport 443 -j ACCEPT
$IPT -A LAN-PUB -s 192.168.14.0/24 -p udp --dport 53 -j ACCEPT

#PUB-LAN 
$IPT -A PUB-LAN -d 192.168.14.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

#LAN-DMZ
$IPT -A LAN-DMZ -s 192.168.14.0/24 -d 10.10.14.0/24 -p icmp --icmp-type 8 -j ACCEPT
$IPT -A LAN-DMZ -s 192.168.14.0/24 -d 10.10.14.0/24 -p tcp -m multiport --dports 80,443 -j ACCEPT
$IPT -A LAN-DMZ -s 192.168.14.0/24 -d 10.10.14.0 -p tcp --dport 21 -j ACCEPT
$IPT -A LAN-DMZ -s 192.168.14.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

#DMZ-LAN
$IPT -A DMZ-LAN -s 10.10.14.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

# DMZ-PUB
$IPT -A DMZ-PUB -s 10.10.14.0/24 -p udp --dport 53 -j ACCEPT
$IPT -A DMZ-PUB -s 10.10.14.0/24 -p tcp --dport 80 -j ACCEPT
$IPT -A DMZ-PUB -s 10.10.14.0/24 -p tcp --dport 443 -j ACCEPT
$IPT -A DMZ-PUB -s 10.10.14.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT 

# PUB-DMZ
$IPT -A PUB-DMZ -d 10.10.14.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A PUB-DMZ -d 10.10.14.10 -p tcp -m multiport --dports 80,443 -j ACCEPT
