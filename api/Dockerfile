FROM node:12

# Expose port via args, default set
ARG expose_port=3000

ARG PORT=3000
ARG LOG_LEVEL=debug
ARG AUTH_PUBLIC_KEY=base64encodedkey

ENV PORT=$PORT
ENV LOG_LEVEL=$LOG_LEVEL
ENV AUTH_PUBLIC_KEY=$AUTH_PUBLIC_KEY

#Connection parameters for vpn host
ENV SSH_HOST='localhost'
ENV SSH_PORT=22
ENV SSH_USERNAME='testssh'
ENV SSH_PASSWORD='testssh@123'
ENV SSH_PRIVATE_KEY='not_yet'
ENV SSH_USE_PASSWORD=1

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./

RUN npm install
# If you are building your code for production
RUN npm ci --only=production

# Bundle app source
COPY . .

EXPOSE $expose_port

CMD [ "npm", "start" ]
