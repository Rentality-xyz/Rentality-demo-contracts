FROM node:18-bullseye-slim AS base

RUN apt-get update && \
 apt-get install --no-install-recommends -y \
 build-essential git ssh
RUN apt clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/app
WORKDIR /home/app

COPY . .

COPY ./docker/env.contracts .env

RUN npm install
