#!/usr/bin/env bash

WEBHOOK_URL=$1
CHANNEL_NAME=$2

MESSAGE=$(cat slack-message.txt)

curl -X POST -H 'Content-type: application/json' --data ${MESSAGE} ${WEBHOOK_URL}