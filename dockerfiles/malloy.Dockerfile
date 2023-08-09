FROM --platform=linux/amd64 node:19.9-slim

WORKDIR /usr/app

RUN npm install -g malloy-cli
