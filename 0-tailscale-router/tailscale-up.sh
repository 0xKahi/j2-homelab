#!/bin/bash
# Reads routes from /root/.tailscale/routes.conf (one CIDR per line)
# and brings up Tailscale with the configured routes.

ROUTES=$(paste -sd ',' /root/.tailscale/routes.conf)

tailscale up \
  --authkey=file:/root/.tailscale/authKey.secret.conf \
  --advertise-routes="$ROUTES" \
  --accept-routes \
  --accept-dns=false
