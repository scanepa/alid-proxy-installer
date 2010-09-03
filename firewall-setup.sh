#!/bin/bash 
# This script is derived from
# http://www.cyberciti.biz/tips/wp-content/uploads/2006/06/fw.proxy.txt 
# (c) 2006, nixCraft under GNU/GPL v2.0+
# (c) 2009, Stefano Canepa <sc@linux.it> under GNU/GPL
#
# Loading gettext to enable i10n
. gettext.sh

TEXTDOMAINDIR=/usr/local/share/locale
TEXTDOMAIN=firewall-setup.sh

usage()
{
echo "`gettext \"usage: $0 options

This script create a squid configuration with squidGuard enabled
If some options are missing the user is asked for them.

OPTIONS:
   -i      Internet interface name
   -l      LAN interface name
   -a      LAN IP address
   -p      Squid port
   -v      Verbose
\"`"
}

setupIptables()
{
# Clean old firewall
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
# Load IPTABLES modules for NAT and IP conntrack support
modprobe ip_conntrack
modprobe ip_conntrack_ftp
# enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
# Setting default filter policy
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
# Unlimited access to loop back
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# Allow UDP, DNS and Passive FTP
iptables -A INPUT -i $inetInt -m state --state ESTABLISHED,RELATED -j ACCEPT
# set this system as a router for Rest of LAN
iptables --table nat --append POSTROUTING --out-interface $inetInt -j MASQUERADE
iptables --append FORWARD --in-interface $lanInt -j ACCEPT
# unlimited access to LAN
iptables -A INPUT -i $lanInt -j ACCEPT
iptables -A OUTPUT -o $lanInt -j ACCEPT
# DNAT port 80 request comming from LAN systems to squid 3128 ($squidPort) aka transparent proxy
iptables -t nat -A PREROUTING -i $lanInt -p tcp --dport 80 -j DNAT --to $lanIP:$squidPort
# if it is same system
iptables -t nat -A PREROUTING -i $inetInt -p tcp --dport 80 -j REDIRECT --to-port $squidPort
# DROP everything and Log it
iptables -A INPUT -j LOG
iptables -A INPUT -j DROP
# save IP tables rules
iptables-save > /etc/firewall.conf

# Generate the if-up script to restore iptables rules
echo "#!/bin/sh" > /etc/network/if-up.d/iptables 
echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/network/if-up.d/iptables
echo "iptables-restore < /etc/firewall.conf" >> /etc/network/if-up.d/iptables 
chmod +x /etc/network/if-up.d/iptables 
}

askInetConfig()
{
# Interface connected to Internet
inetIntDefault="eth0"
inetIntDefPrompt="["$inetIntDefault"]: "
# ask the squid server IP
read -p "`gettext \"Proxy server Internet interface name \"`"$inetIntDefPrompt t1
if [ -n "$t1" ]
then
    inetInt="$t1"
else
    inetInt="$inetIntDefault"
fi
# Inet
inetIPdefault=`ip addr|grep "inet " | grep $inetInt | cut -f 6 -d " " | cut -f 1 -d"/"`
inetIPDefPrompt="["$inetIPdefault"]: "
read -p "`gettext \"Proxy server Internet IP address \"`"$inetIPDefPrompt t3
if [ -n "$t3" ]
then
    inetIP="$t3"
else
    inetIP="$inetIPDefault"
fi
}

askLANConfig()
{
# Interface connected to LAN
lanIntDefault="eth1"
lanIntDefPrompt="["$lanIntDefault"]: "
read -p "`gettext \"Proxy server LAN interface name \"`"$lanIntDefPrompt t2
if [ -n "$t2" ]
then
    lanInt="$t2"
else
    lanInt="$lanIntDefault"
fi

lanIPdefault=`ip addr|grep "inet " | grep $lanInt | cut -f 6 -d " " | cut -f 1 -d"/"`
lanIPDefPrompt="["$lanIPdefault"]: "
read -p "`gettext \"Proxy server LAN IP address \"`"$lanIPDefPrompt t3
if [ -n "$t3" ]
then
    lanIP="$t3"
else
    lanIP="$lanIPdefault"
fi
}
askSquidPort()
{
# set up squid port default
read -p "`gettext \"Squid port number [$squidPortDefault]: \"`" t4
if [ -n "$t4" ]
then
    squidPort="$t4"
else
    squidPort="$squidPortDefault"
fi
}

VERBOSE=0
# parse command line
while getopts “hi:l:a:p:v” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         i) 
	     inetInt=$OPTARG
	     ;;
	 l)
             lanInt=$OPTARG
             ;;
         a)
             lanIP=$OPTARG
             ;;
	 p) 
	     squidPort=$OPTARG
	     ;;
         v)
             VERBOSE=1
             ;;
     esac
done

# Internet configuration was not provided on the command line
if [[ -z $inetInt ]]
then
    VERBOSE=1
    askInetConfig
fi
# LAN configuration was not provided on the command line
if [[ -z $lanInt ]] || [[ -z $lanIP ]]
then
    VERBOSE=1
    askLANConfig
fi
# 
if [[ -z $squidPort ]]
then
    VERBOSE=1
    squidPortDefault="3128"
    askSquidPort
fi

# if the command line is completed
setupIptables

