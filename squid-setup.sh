#!/bin/bash
# This script is derived from
# http://www.cyberciti.biz/tips/wp-content/uploads/2006/06/fw.proxy.txt 
# (c) 2006, nixCraft under GNU/GPL v2.0+
# (c) 2009, Stefano Canepa <sc@linux.it> under GNU/GPL
#
# Loading gettext to enable i10n
. gettext.sh

#
# If this script is called without parameters it asks the user, if run
# with all parameters can run silently so that it can be used in other
# scripts. All missing parameters are asked to the user
# or by passing arguments on 
#
usage()
{
echo "`gettext \"usage: $0 options

This script create a squid configuration with squidGuard enabled
If some options are missing the user is asked for them.

OPTIONS:
   -i      Internet interface IP address (i.e.: 192.168.1.1)
   -l      LAN network in CIDR notation (i.e.: 192.168.2.0/24)
   -v      Verbose
\"`"
}

askInetConfig()
{
# Interface connected to Internet
inetIntDefault="eth0"
inetIntDefPrompt="["$inetIntDefault"]: "
read -p "`gettext \"Proxy server Internet interface name \"`"$inetIntDefPrompt t1
if [ -n "$t1" ]
then
    inetInt="$t1"
else
    inetInt="$inetIntDefault"
fi
#
# ask the squid server IP
#
inetIPDefault=`ip addr|grep "inet " | grep $inetInt | cut -f 6 -d " " | cut -f 1 -d"/"`
inetIPDefPrompt="["$inetIPDefault"]: "
read -p "`gettext \"Proxy server Internet IP address \"`"$inetIPDefPrompt t1
if [ -n "$t1" ]
then
    inetIPAddr="$t1"
else
    inetIPAddr="$inetIPDefault"
fi
}

#
# Asks for the LAN interface's name, get it IP address 
# and guess the LAN IP class. 
# The user is asked to confirm or modify information
#
askLANConfig()
{
#
# Interface connected to LAN
#
# Guess eth1 is connected to private LAN
lanIntDefault="eth1"
lanIntDefPrompt="["$lanIntDefault"]: "
read -p "`gettext \"Proxy server LAN interface \"`"$lanIntDefPrompt t1
if [ -n "$t1" ]
then
    lanInt="$t1"
else
    lanInt="$inetIPDefault"
fi
#
# LAN IP class in CIDR notification
#
# get the first 3 bytes of the IP address of the interface entered before
netStartingBytes=`ip addr |grep "inet " | grep $lanInt | cut -f 6 -d " " | cut -f 1 -d " " | cut -f 1 -d "/" | awk -F"." '{print $1"."$2"."$3}'`
# get the LAN IP class
lanIPClassDefault=`ip route | grep $lanInt | cut -f 1 -d " " | grep $netStartingBytes`
lanIPClassDefPrompt="["$lanIPClassDefault"]: "
read -p "`gettext \"Proxy server LAN IP class \"`"$lanIPClassDefPrompt t1
if [ -n "$t1" ]
then
    lanIPClass="$t1"
else
    lanIPClass="$lanIPClassDefault"
fi
}

createSquidConf()
{
#
# backup configuration
#
if [[ $VERBOSE == 1 ]]
then
    echo "`gettext \"Backing up /etc/squid/squid.conf...\"`"
fi
mv /etc/squid3/squid.conf /etc/squid3/squid.conf.dist
if [[ $VERBOSE == 1 ]]
then
    echo "`gettext \"Creating new /etc/squid3/squid.conf...\"`"
fi
cat > /etc/squid3/squid.conf <<STOP
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl manager proto cache_object
acl localhost src 127.0.0.1/32
acl to_localhost dst 127.0.0.0/8
STOP
echo "acl lan src $inetIPAddr $lanIPClass" >> /etc/squid3/squid.conf
cat >> /etc/squid3/squid.conf <<EOF 
acl SSL_ports port 443
acl CONNECT method CONNECT
http_access allow manager localhost
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost
htcp_access deny all
http_access allow lan
http_access deny all
icp_access deny all
http_port 3128 transparent
hierarchy_stoplist cgi-bin ?
access_log /var/log/squid3/access.log squid
acl QUERY urlpath_regex cgi-bin \?
cache deny QUERY
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern .		0	20%	4320
icp_port 3130
coredump_dir /var/spool/squid3
EOF
echo "redirect_program /usr/bin/squidGuard -c /etc/squid/squidGuard.conf" >> /etc/squid3/squid.conf
}

#
# main
#

# setup data for the internationalization
TEXTDOMAINDIR=/usr/local/share/locale
TEXTDOMAIN=firewall-setup.sh

VERBOSE=0
# parse command line
while getopts “hi:l:v” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         i)
             inetIPAddr=$OPTARG
             ;;
         l)
             lanIPClass=$OPTARG
             ;;
         v)
             VERBOSE=1
             ;;
     esac
done

# Internet configuration was not provided on the command line
if [[ -z $inetIPAddr ]]
then
    VERBOSE=1
    askInetConfig
fi
# LAN IP class was not provided on the command line
if [[ -z $lanIPClass ]]
then
    VERBOSE=1
    askLANConfig
fi
# if the command line is completed
createSquidConf
