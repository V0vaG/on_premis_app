#!/bin/bash
site_ip=localhost
site=$(curl -Is $site_ip | head -n 1)
status_code=$(echo $site | awk '{print $2}')

if (( "$status_code" >= 200 && "$status_code" < 400 )); then
  echo "The code: $status_code, The site is on-line :-)"
  exit 0
else
  echo "The code: $status_code, The site is down :-("
  exit 1
fi 

