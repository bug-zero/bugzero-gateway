#!/usr/bin/env bash

echo
echo "=== https://github.com/bug-zero/bugzero-gateway ==="
echo

#Exit when error - first argument is the reason of the error
function exit_badly {
  echo $1
  exit 1
}

#Script is intend to run inside a ubuntu 18.04+ container
[[ $(lsb_release -rs) == "18.04" ]] || exit_badly "This script is for Ubuntu 18.04 and up, aborting..."

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
DEFAULTVPNHOST=${IP}

echo "Network interface: ${ETH0ORSIMILAR}"
echo "External IP: ${IP}"
echo
#echo "** Note: hostname must resolve to this machine already, to enable Let's Encrypt certificate setup **"

read -p "Hostname for VPN (default: ${DEFAULTVPNHOST}): " VPNHOST
VPNHOST=${VPNHOST:-$DEFAULTVPNHOST}

VPNHOSTIP=${VPNHOST}

#VPNHOSTIP=$(dig -4 +short "$VPNHOST")
#[[ -n "$VPNHOSTIP" ]] || exit_badly "Cannot resolve VPN hostname, aborting"

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

# Default DNS
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

CURDIR=$(pwd)

mkdir -p /etc/vpncert/$VPNHOST
cd /etc/vpncert/$VPNHOST

#Generate CA
openssl genrsa -out CA-key.pem 4096
printf "LK\nWestern Province\nColombo\nSCoReLab\n\n\n\n" | openssl req -new -key CA-key.pem -x509 -days 1000 -out CA-cert.pem

#Generate Server Private Key
openssl genrsa -out private.pem 2048

#Generate CSR
#printf "LK\nWestern Province\nColombo\nSCoReLab\n\n$VPNHOST\n\n\n\n" | openssl req -new -key private.pem -out signingReq.csr

openssl req -new -key private.pem -subj "/C=LK/ST=WP/O=BugZero, Inc./CN=$VPNHOST -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=$VPNHOST")) -out signingReq.csr

#Generate signed cert
openssl x509 -req -days 365 -in signingReq.csr -CA CA-cert.pem -CAkey CA-key.pem -CAcreateserial -out cert.pem

cd $CURDIR

#mkdir -p /etc/letsencrypt
#
#echo 'rsa-key-size = 4096
#pre-hook = /sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT
#post-hook = /sbin/iptables -D INPUT -p tcp --dport 80 -j ACCEPT
#renew-hook = /usr/sbin/ipsec reload && /usr/sbin/ipsec secrets
#' > /etc/letsencrypt/cli.ini
#
#certbot certonly --non-interactive --agree-tos --standalone --preferred-challenges http --email $EMAILADDR -d $VPNHOST

ln -f -s /etc/vpncert/$VPNHOST/cert.pem    /etc/ipsec.d/certs/cert.pem
ln -f -s /etc/vpncert/$VPNHOST/private.pem /etc/ipsec.d/private/privkey.pem
ln -f -s /etc/vpncert/$VPNHOST/CA-cert.pem   /etc/ipsec.d/cacerts/chain.pem

grep -Fq 'bug-zero/bugzero-gateway' /etc/apparmor.d/local/usr.lib.ipsec.charon || echo "
# https://github.com/bug-zero/bugzero-gateway
/etc/vpncert/* r,
" >> /etc/apparmor.d/local/usr.lib.ipsec.charon

aa-status --enabled && invoke-rc.d apparmor reload

echo
echo "--- Configuring VPN ---"
echo

# ip_forward is for VPN
# ip_no_pmtu_disc is for UDP fragmentation
# others are for security

grep -Fq 'bug-zero/bugzero-gateway' /etc/sysctl.conf || echo '
# https://github.com/bug-zero/bugzero-gateway
net.ipv4.ip_forward = 1
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
' >> /etc/sysctl.conf

sysctl -p

# these ike and esp settings are tested on Mac 10.14, iOS 12 and Windows 10
# iOS and Mac with appropriate configuration profiles use AES_GCM_16_256/PRF_HMAC_SHA2_384/ECP_521
# Windows 10 uses AES_GCM_16_256/PRF_HMAC_SHA2_384/ECP_384

echo "config setup
  strictcrlpolicy=yes
  uniqueids=never

conn roadwarrior
  auto=add
  compress=no
  type=tunnel
  keyexchange=ikev2
  fragmentation=yes
  forceencaps=yes
  ike=aes256gcm16-prfsha384-ecp521,aes256gcm16-prfsha384-ecp384!
  esp=aes256gcm16-ecp521,aes256gcm16-ecp384!
  dpdaction=clear
  dpddelay=900s
  rekey=no
  left=%any
  leftid=@${VPNHOST}
  leftcert=cert.pem
  leftsendcert=always
  leftsubnet=0.0.0.0/0
  right=%any
  rightid=%any
  rightauth=eap-mschapv2
  eap_identity=%any
  rightdns=${VPNDNS}
  rightsourceip=${VPNIPPOOL}
  rightsendcert=never
" > /etc/ipsec.conf

echo "${VPNHOST} : RSA \"privkey.pem\"
${VPNUSERNAME} : EAP \""${VPNPASSWORD}"\"
" > /etc/ipsec.secrets

ipsec restart


#echo
#echo "--- User ---"
#echo
#
## user + SSH
#
#id -u $LOGINUSERNAME &>/dev/null || adduser --disabled-password --gecos "" $LOGINUSERNAME
#echo "${LOGINUSERNAME}:${LOGINPASSWORD}" | chpasswd
#adduser ${LOGINUSERNAME} sudo
#
#sed -r \
#-e "s/^#?Port 22$/Port ${SSHPORT}/" \
#-e 's/^#?LoginGraceTime (120|2m)$/LoginGraceTime 30/' \
#-e 's/^#?PermitRootLogin yes$/PermitRootLogin no/' \
#-e 's/^#?X11Forwarding yes$/X11Forwarding no/' \
#-e 's/^#?UsePAM yes$/UsePAM no/' \
#-i.original /etc/ssh/sshd_config
#
#grep -Fq 'bug-zero/bugzero-gateway' /etc/ssh/sshd_config || echo "
## https://github.com/bug-zero/bugzero-gateway
#MaxStartups 1
#MaxAuthTries 2
#UseDNS no" >> /etc/ssh/sshd_config
#
#if [[ $CERTLOGIN = "y" ]]; then
#  mkdir -p /home/${LOGINUSERNAME}/.ssh
#  chown $LOGINUSERNAME /home/${LOGINUSERNAME}/.ssh
#  chmod 700 /home/${LOGINUSERNAME}/.ssh
#
#  cp /root/.ssh/authorized_keys /home/${LOGINUSERNAME}/.ssh/authorized_keys
#  chown $LOGINUSERNAME /home/${LOGINUSERNAME}/.ssh/authorized_keys
#  chmod 600 /home/${LOGINUSERNAME}/.ssh/authorized_keys
#
#  sed -r \
#  -e "s/^#?PasswordAuthentication yes$/PasswordAuthentication no/" \
#  -i.allows_pwd /etc/ssh/sshd_config
#fi
#
#service ssh restart


echo
echo "--- Timezone, mail, unattended upgrades ---"
echo

timedatectl set-timezone $TZONE
/usr/sbin/update-locale LANG=en_GB.UTF-8


#sed -r \
#-e "s/^myhostname =.*$/myhostname = ${VPNHOST}/" \
#-e 's/^inet_interfaces =.*$/inet_interfaces = loopback-only/' \
#-i.original /etc/postfix/main.cf

#grep -Fq 'bug-zero/bugzero-gateway' /etc/aliases || echo "
## https://github.com/bug-zero/bugzero-gateway
#root: ${EMAILADDR}
#${LOGINUSERNAME}: ${EMAILADDR}
#" >> /etc/aliases

newaliases
service postfix restart


sed -r \
-e 's|^//Unattended-Upgrade::MinimalSteps "true";$|Unattended-Upgrade::MinimalSteps "true";|' \
-e 's|^//Unattended-Upgrade::Mail "root";$|Unattended-Upgrade::Mail "root";|' \
-e 's|^//Unattended-Upgrade::Automatic-Reboot "false";$|Unattended-Upgrade::Automatic-Reboot "true";|' \
-e 's|^//Unattended-Upgrade::Remove-Unused-Dependencies "false";|Unattended-Upgrade::Remove-Unused-Dependencies "true";|' \
-e 's|^//Unattended-Upgrade::Automatic-Reboot-Time "02:00";$|Unattended-Upgrade::Automatic-Reboot-Time "03:00";|' \
-i /etc/apt/apt.conf.d/50unattended-upgrades

echo 'APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
' > /etc/apt/apt.conf.d/10periodic

service unattended-upgrades restart

source ./client-config.sh

