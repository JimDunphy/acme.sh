#!/usr/bin/bash

#Here is a script to deploy cert to stalwart mail server.
HTTPS_DIR="/opt/stalwart/etc/certs"

# location of stalwart-cli if present
export PATH=/opt/stalwart/bin:$PATH

#=============================================================
# Configuration
#=============================================================

# Step 0: if you want to reload and have stalwart-cli installed, then change the password below.
# If password is left as change-me, then this script will use systemctl restart stalwart to load the new certs
STALWART_URL="${STALWART_URL:-http://localhost:8080}"
STALWART_USER="${STALWART_USER:-admin}"
STALWART_PASS="${STALWART_PASS:-"change-me"}"

# Step 1: Add the following to /opt/stalwart/etc/config.toml
#certificate.default.cert = "%{file:/opt/stalwart/etc/certs/mail.example.com/fullchain.pem}%"
#certificate.default.private-key = "%{file:/opt/stalwart/etc/certs/mail.example.com/privkey.pem}%"
#certificate.default.default = true
#
# Step 2: mkdir -p /opt/stalwart/etc/certs/mail.example.com
# Step 3: copy this script to your acme.sh/deploy directory
#
# Author: J Dunphy 8/15/2025
#         10/5/2025 - recommendation from myriad007 to use stalwart-cli with reload-certificates
#

reload_stalwart_cli() {
    if command -v stalwart-cli >/dev/null 2>&1; then
        echo "stalwart-cli found, attempting to reload certificates..."
        stalwart-cli -c "$STALWART_USER:$STALWART_PASS" -u "$STALWART_URL" server reload-certificates
        return $?
    fi
    return 127
}

restart_stalwart_systemd() {
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl list-unit-files | grep -q '^stalwart\.service'; then
            echo "Restarting stalwart.service..."
            systemctl restart stalwart
        elif systemctl list-unit-files | grep -q '^stalwart-mail\.service'; then
            echo "Restarting stalwart-mail.service..."
            systemctl restart stalwart-mail
        else
            echo "No stalwart systemd service found."
        fi
    fi
}


#returns 0 means success, otherwise error.

########  Public functions #####################

#domain keyfile certfile cafile fullchain
stalwart_deploy() {
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  _debug _cdomain "$_cdomain"
  _debug _ckey "$_ckey"
  _debug _ccert "$_ccert"
  _debug _cca "$_cca"
  _debug _cfullchain "$_cfullchain"

  cp -f "$_ckey" $HTTPS_DIR/$_cdomain/privkey.pem
  cp -f "$_ccert" $HTTPS_DIR/$_cdomain/cert.pem
  cp -f "$_cfullchain" $HTTPS_DIR/$_cdomain/fullchain.pem

  # Set ownership to stalwart-mail if this doesn't run as the stalwart user or comment this out if it does
  sudo chown stalwart:stalwart "${HTTPS_DIR}/$_cdomain/fullchain.pem" "${HTTPS_DIR}/$_cdomain/privkey.pem"

  /bin/logger -p local2.info NETWORK "Certificate has been Renewed for $_cdomain"

  # Have stalwart reload the certificates
  if [ "$STALWART_PASS" != "change-me" ]; then
     reload_stalwart_cli || restart_stalwart_systemd
  else
     echo "No custom STALWART_PASS provided — skipping CLI reload and restarting service instead."
     restart_stalwart_systemd
  fi

  return 0

}
