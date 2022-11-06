#!/bin/sh

rsp_login=$(curl -s \
  --form-string "email=$1" \
  --form-string "password=$2" \
  --form-string "twofa=$3" \
  https://api.pushover.net/1/users/login.json)

secret=$(printf "%s" "$rsp_login" | jq --raw-output '.secret')

rsp_devices=$(curl -s \
  --form-string "secret=$secret" \
  --form-string "name=ptx" \
  --form-string "os=O" \
  https://api.pushover.net/1/devices.json)

device_id=$(printf "%s" "$rsp_devices" | jq --raw-output '.id')

printf "Device ID: %s\nSecret: %s\n" "$device_id" "$secret"

