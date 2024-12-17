#!/bin/bash

# Check if port argument is provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 <port>"
  exit 1
fi

site_ip="localhost:$1"

# Fetch HTTP response
site=$(curl -Is --max-time 5 "$site_ip" 2>/dev/null | head -n 1)
status_code=$(echo "$site" | awk '{print $2}')

# Check if status_code is not empty and valid
if [[ -n "$status_code" && "$status_code" =~ ^[0-9]+$ ]]; then
  if ((status_code >= 200 && status_code < 400)); then
    echo "The code: $status_code, The site is online on: $site_ip :-)"
    exit 0
  else
    echo "The code: $status_code, The site is down :-("
    exit 1
  fi
else
  echo "Failed to fetch site status or invalid response."
  exit 1
fi

