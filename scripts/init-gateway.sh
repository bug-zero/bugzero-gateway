#!/usr/bin/env bash

echo
echo "=== https://github.com/scorelab/bugzero-gateway ==="
echo

#Exit when error - first argument is the reason of the error
function exit_badly {
  echo $1
  exit 1
}

#Script is intend to run inside a ubuntu 18.04 container
[[ $(lsb_release -rs) == "18.04" ]] || exit_badly "This script is for Ubuntu 18.04 only, aborting..."

#Check root user
[[ $(id -u) -eq 0 ]] || exit_badly "Please re-run as root (e.g. sudo ./path/to/this/script)"

echo "--- Updating and installing software ---"
echo

#Setup repositories
export DEBIAN_FRONTEND=noninteractive

apt-get -o Acquire::ForceIPv4=true update
apt-get -o Acquire::ForceIPv4=true install -y software-properties-common
add-apt-repository universe
add-apt-repository restricted
add-apt-repository multiverse

apt-get -o Acquire::ForceIPv4=true --with-new-pkgs upgrade -y
apt autoremove -y

#Install dependencies
apt -o Acquire::ForceIPv4=true install -y language-pack-en strongswan libstrongswan-standard-plugins strongswan-libcharon libcharon-standard-plugins libcharon-extra-plugins moreutils iptables-persistent postfix mutt unattended-upgrades certbot dnsutils uuid-runtime


echo
echo "--- Configuration: VPN settings ---"
echo

ETH0ORSIMILAR=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
IP=$(ifdata -pa $ETH0ORSIMILAR)

PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [[ $PUBLIC_IP != "" ]]; then
    IP=$PUBLIC_IP
fi

#This is used to obtain certificates from Lets Encrypt
#For testing purpose only
#We will create own CA later
DEFAULTVPNHOST=${IP}.sslip.io


