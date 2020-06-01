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

echo "Network interface: ${ETH0ORSIMILAR}"
echo "External IP: ${IP}"
echo
echo "** Note: hostname must resolve to this machine already, to enable Let's Encrypt certificate setup **"

read -p "Hostname for VPN (default: ${DEFAULTVPNHOST}): " VPNHOST
VPNHOST=${VPNHOST:-$DEFAULTVPNHOST}

VPNHOSTIP=$(dig -4 +short "$VPNHOST")
[[ -n "$VPNHOSTIP" ]] || exit_badly "Cannot resolve VPN hostname, aborting"

if [[ "$IP" != "$VPNHOSTIP" ]]; then
  echo "Warning: $VPNHOST resolves to $VPNHOSTIP, not $IP"
  echo "Either you are behind NAT, or something is wrong (e.g. hostname points to wrong IP, CloudFlare proxying shenanigans, ...)"
  read -p "Press [Return] to continue, or Ctrl-C to abort" DUMMYVAR
fi

#Only For debug purposes.
read -p "VPN username: " VPNUSERNAME
while true; do
read -s -p "VPN password (no quotes, please): " VPNPASSWORD
echo
read -s -p "Confirm VPN password: " VPNPASSWORD2
echo
[[ "$VPNPASSWORD" = "$VPNPASSWORD2" ]] && break
echo "Passwords didn't match -- please try again"
done

echo '
Public DNS servers include:

176.103.130.130,176.103.130.131  AdGuard               https://adguard.com/en/adguard-dns/overview.html
176.103.130.132,176.103.130.134  AdGuard Family        https://adguard.com/en/adguard-dns/overview.html
1.1.1.1,1.0.0.1                  Cloudflare/APNIC      https://1.1.1.1
84.200.69.80,84.200.70.40        DNS.WATCH             https://dns.watch
8.8.8.8,8.8.4.4                  Google                https://developers.google.com/speed/public-dns/
208.67.222.222,208.67.220.220    OpenDNS               https://www.opendns.com
208.67.222.123,208.67.220.123    OpenDNS FamilyShield  https://www.opendns.com
9.9.9.9,149.112.112.112          Quad9                 https://quad9.net
77.88.8.8,77.88.8.1              Yandex                https://dns.yandex.com
77.88.8.88,77.88.8.2             Yandex Safe           https://dns.yandex.com
77.88.8.7,77.88.8.3              Yandex Family         https://dns.yandex.com
'

read -p "DNS servers for VPN users (default: 1.1.1.1,1.0.0.1): " VPNDNS
VPNDNS=${VPNDNS:-'1.1.1.1,1.0.0.1'}

echo
echo "--- Configuration: general server settings ---"
echo

read -p "Timezone (default: Europe/London): " TZONE
TZONE=${TZONE:-'Europe/London'}

# Debug

read -p "Email address for sysadmin (e.g. j.bloggs@example.com): " EMAILADDR

read -p "Desired SSH log-in port (default: 22): " SSHPORT
SSHPORT=${SSHPORT:-22}

# End debug

VPNIPPOOL="10.10.0.0/16"
source ./vpnpool.sh

echo
echo "--- Configuring firewall ---"
echo

# firewall
# https://www.strongswan.org/docs/LinuxKongress2009-strongswan.pdf
# https://wiki.strongswan.org/projects/strongswan/wiki/ForwardingAndSplitTunneling
# https://www.zeitgeist.se/2013/11/26/mtu-woes-in-ipsec-tunnels-how-to-fix/

iptables -P INPUT   ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT  ACCEPT

iptables -F
iptables -t nat -F
iptables -t mangle -F

# INPUT

# accept anything already accepted
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# accept anything on the loopback interface
iptables -A INPUT -i lo -j ACCEPT

# drop invalid packets
iptables -A INPUT -m state --state INVALID -j DROP

# rate-limit repeated new requests from same IP to any ports
iptables -I INPUT -i $ETH0ORSIMILAR -m state --state NEW -m recent --set
iptables -I INPUT -i $ETH0ORSIMILAR -m state --state NEW -m recent --update --seconds 300 --hitcount 60 -j DROP

# Debug
# accept (non-standard) SSH
iptables -A INPUT -p tcp --dport $SSHPORT -j ACCEPT

# End debug

# VPN

# accept IPSec/NAT-T for VPN (ESP not needed with forceencaps, as ESP goes inside UDP)
iptables -A INPUT -p udp --dport  500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT

# forward VPN traffic anywhere
iptables -A FORWARD --match policy --pol ipsec --dir in  --proto esp -s $VPNIPPOOL -j ACCEPT
iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d $VPNIPPOOL -j ACCEPT

# reduce MTU/MSS values for dumb VPN clients
iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s $VPNIPPOOL -o $ETH0ORSIMILAR -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360

# masquerade VPN traffic over eth0 etc.
iptables -t nat -A POSTROUTING -s $VPNIPPOOL -o $ETH0ORSIMILAR -m policy --pol ipsec --dir out -j ACCEPT  # exempt IPsec traffic from masquerading
iptables -t nat -A POSTROUTING -s $VPNIPPOOL -o $ETH0ORSIMILAR -j MASQUERADE


# fall through to drop any other input and forward traffic

iptables -A INPUT   -j DROP
iptables -A FORWARD -j DROP

iptables -L

debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v4 boolean true"
debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v6 boolean true"
dpkg-reconfigure iptables-persistent

echo
echo "--- Configuring RSA certificates ---"
echo

mkdir -p /etc/letsencrypt

echo 'rsa-key-size = 4096
pre-hook = /sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT
post-hook = /sbin/iptables -D INPUT -p tcp --dport 80 -j ACCEPT
renew-hook = /usr/sbin/ipsec reload && /usr/sbin/ipsec secrets
' > /etc/letsencrypt/cli.ini

certbot certonly --non-interactive --agree-tos --standalone --preferred-challenges http --email $EMAILADDR -d $VPNHOST

ln -f -s /etc/letsencrypt/live/$VPNHOST/cert.pem    /etc/ipsec.d/certs/cert.pem
ln -f -s /etc/letsencrypt/live/$VPNHOST/privkey.pem /etc/ipsec.d/private/privkey.pem
ln -f -s /etc/letsencrypt/live/$VPNHOST/chain.pem   /etc/ipsec.d/cacerts/chain.pem

grep -Fq 'scorelab/bugzero-gateway' /etc/apparmor.d/local/usr.lib.ipsec.charon || echo "
# https://github.com/scorelab/bugzero-gateway
/etc/letsencrypt/archive/${VPNHOST}/* r,
" >> /etc/apparmor.d/local/usr.lib.ipsec.charon

aa-status --enabled && invoke-rc.d apparmor reload

