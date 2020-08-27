# bugzero-gateway
Bug Zero Gateway is a VPN and that help to provide researcher to access private programs, and also program owner can monitor researcher activities for findings. 

## Initialising VPN server

This initialises a IPSec VPN sever with IKEv2 authentication.

**Requirements**

- Ubuntu 18.04 VM with public IP
- Docker installation 

First you should run `init-gateway.sh` script as root user. Then it will prompt some inputs to fill. 
After that, complete VPN server is ready.

Script will generate CA for you. You need to obtain the certificate signed by that CA. 
Then client can connect using that certificate.

Copy and keep `CA-cert.pem` `cert.pem` files from `/etc/vpncert/${vpn_host_address}` 
since you need to send those files to client to configure VPN connection to server

Additional user authentication can be controlled through API.

After successful execution, a VPN server is up and client configuration will be written to the `/etc`. Following files will be available.

- `/etc/vpn-instructions.txt`
- `/etc/vpn-ios-or-mac.mobileconfig`
- `/etc/vpn-ubuntu-client.sh`


## Client configuration

#### Ubuntu

First you need to obtain the `vpn-ubuntu-client.sh`.

**Automatic certificate configuration**

You need to have certificate file, and the CA certificate file.
Then you can run the client by executing following,
`sudo ./vpn-ubuntu-client.sh -u username -c certificate_path -a CA_path`

Password will be prompted when running.

**Manual Certificate configuration**

You can choose to skip automatic custom certificate configurations by typeing,

`sudo ./vpn-ubuntu-client.sh -u username --skip-cert`

If you choose to skip certificate configuration and still need to configure them later, do the following.
You need to copy the certificates that you get from the server to following directories.

- `CA-cert.pem` to `/etc/ipsec.d/cacerts/` (File name does not matter)
- `cert.pem` to `/etc/ipsec.d/certs/` (File name maters. If you rename cert.pem in to any other name change `leftcert=<new_cert_name>` in `/etc/ipsec.conf`)

**Note: Disable IPv6 since this only supports IPv4. Otherwise traffic will be routed through IPv6**

Now client is ready to connect to server.

To start connection:
`sudo ipsec up ikev2vpn`

To stop connection:
`sudo ipsec down ikev2vpn`

#### Android

Download the strongSwan app from the Play Store: https://play.google.com/store/apps/details?id=org.strongswan.android

Server: vpn server address
VPN Type: IKEv2 EAP (Username/Password)
Username and password: as configured on the server
CA certificate: Install CA certificate
