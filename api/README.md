# vpn API

This initialises API to control the VPN sever.

## Setup

**Without docker** 

You first need to configure the environment. You can copy the `.env.stub` as `.env`. Then you need to configure following variables before starting the server.

```bash
# Which port server is running. Default 3000
PORT=3000 

# Base64 encoded public key in single line.
AUTH_PUBLIC_KEY=base64encoded_public_key 

# Not required for server, only for testing
AUTH_PRIVATE_KEY=base64encoded_private_key 

# Set log level. Default debug
LOG_LEVEL=debug 

# If value is 1 authentication header won't be checked, Any other value will check the token.
SKIP_TOKEN_CHECK=0

# Important.
# You need to configure ssh user with sudo privileges. Also that user must able to run sudo commands without asking password
#Connection parameters for vpn host
SSH_HOST=localhost
SSH_PORT=22
SSH_USERNAME=testssh

#If value is 1 you must set the SSH_PASSWORD variable, otherwise you must set SSH_PRIVATE_KEY
SSH_USE_PASSWORD=1
SSH_PASSWORD=testssh@123

# SSH private key in base64 format in single line
SSH_PRIVATE_KEY='not_yet'
```

## Start API server

First install dependencies.
`npm install`

Then start the server.

`npm start`

## Using docker

### Building docker image
