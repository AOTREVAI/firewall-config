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
$IPT -P OUTPUT ACCEPT

# Kernel setup, abilita il forwarding a livello di kernel
echo 1 > /proc/sys/net/ipv4/ip_forward

# Local accept
$IPT -A INPUT -i lo -j ACCEPT

# SNAT
$IPT -t nat -A POSTROUTING -O enp0s3 -s 192.168.10.0/24 -j SNAT --to-source 172.22.202.10

# INPUT
# aprire porta per ssh su (i)nterfaccia (s)ource (p)rotocol porta
$IPT -A INPUT -i enp0s3 -s 172.22.202.102 -p tcp --dport 2222 -j ACCEPT  

# apre la porta per connessioni iniziate da noi e ancora attive
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# abilita il ping
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT


# FORWARD
$IPT -A FORWARD -i enp0s8 -o enp0s3 -s 192.168.10.0/24 -p icmp --icmp-type 8 -j ACCEPT

$IPT -A FORWARD -i enp0s3 -o enp0s8 -s 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPT -A FORWARD -i enp0s8 -o enp0s9 -s 192.168.10.0/24 -d 10.10.10.0/24 -p icmp --icmp-type 8 -j ACCEPT

$IPT -A FORWARD -i enp0s9 -o enp0s8 -s 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT


# Kernel setup, abilita il forwarding a livello di kernel
echo 1 > /proc/sys/net/ipv4/ip_forward

# Local accept
$IPT -A INPUT -i lo -j ACCEPT

# SNAT
$IPT -t nat -A POSTROUTING -O enp0s3 -s 192.168.10.0/24 -j SNAT --to-source 172.22.202.10

# INPUT
# aprire porta per ssh su (i)nterfaccia (s)ource (p)rotocol porta
$IPT -A INPUT -i enp0s3 -s 172.22.202.102 -p tcp --dport 2222 -j ACCEPT  

# apre la porta per connessioni iniziate da noi e ancora attive
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# abilita il ping
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT


# FORWARD
$IPT -A FORWARD -i enp0s8 -o enp0s3 -s 192.168.10.0/24 -p icmp --icmp-type 8 -j ACCEPT

$IPT -A FORWARD -i enp0s3 -o enp0s8 -s 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPT -A FORWARD -i enp0s8 -o enp0s9 -s 192.168.10.0/24 -d 10.10.10.0/24 -p icmp --icmp-type 8 -j ACCEPT

$IPT -A FORWARD -i enp0s9 -o enp0s8 -s 192.168.10.0/24 -m state --state ESTABLISHED,RELATED -j ACCEPT

