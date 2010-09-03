#!/bin/sh
# this script needs root access rights
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
    lanInt="$lanIntDefault"
fi
#
# ask the private LAN IP address of the server
#
lanIPDefault=`ip addr|grep "inet " | grep $lanInt | cut -f 6 -d " " | cut -f 1 -d"/"`
lanIPDefPrompt="["$lanIPDefault"]: "
read -p "`gettext \"Proxy server LAN IP address \"`"$lanIPDefPrompt t1
if [ -n "$t1" ]
then
    lanIPAddr="$t1"
else
    lanIPAddr="$lanIPDefault"
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

askSquidPort()
{
read -p "`gettext \"Squid port number [$squidPortDefault]: \"`" t4
if [ -n "$t4" ]
then
    squidPort="$t4"
else
    squidPort="$squidPortDefault"
fi
}


install()
{
if [ $VERBOSE -eq 1 ]
then
    echo "`gettext \"Getting selections from the saved one...\"`"
fi
dpkg --set-selections < selections
if [ $VERBOSE -eq 1 ]
then
    echo "`gettext \"Installing selected packages...\"`"
fi
apt-get dselect-upgrade
}

#
# main
#
if [ "$(whoami)" != "root" ]
then
    echo "`gettext \"$0 needs root access rights.\"`"
    echo "`gettext \"Run 'sudo su' and the rerun this $0\"`"
    echo
    exit 1
fi
# setup data for the internationalization
TEXTDOMAINDIR=/usr/local/share/locale
TEXTDOMAIN=firewall-setup.sh

VERBOSE=0
# parse command line
while getopts “hi:l:p:v” OPTION
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
	 p)
	     squidPort=$OPTARG
	     ;;
         v)
             VERBOSE=1
             ;;
     esac
done

# squid port
if [ -z $squidPort ]
then
# set up squid port default
    squidPortDefault="3128"
    VERBOSE=1
    askSquidPort
fi
# Internet configuration was not provided on the command line
if [ -z $inetIPAddr ]
then
    VERBOSE=1
    askInetConfig
fi
# LAN IP class was not provided on the command line
if [ -z $lanIPClass ]
then
    VERBOSE=1
    askLANConfig
fi
# if the command line is completed
install
./firewall-setup.sh -i$inetInt -l$lanInt -a$lanIPAddr -p$squidPort
./squid-setup.sh -i$inetIPAddr -l$lanIPClass

if [ $VERBOSE -eq 1 ]
then
    echo "`gettext \"Updating squidGuard configuration and DB...\"`"
fi
./squidGuard-setup.py

