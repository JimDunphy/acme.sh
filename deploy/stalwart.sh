#!/usr/bin/bash

#Here is a script to deploy cert to stalwart mail server.
HTTPS_DIR="/opt/stalwart/etc/certs"

# Step 1: Add the following to /opt/stalwart/etc/config.toml
#certificate.default.cert = "%{file:/opt/stalwart/etc/certs/mail.example.com/fullchain.pem}%"
#certificate.default.private-key = "%{file:/opt/stalwart/etc/certs/mail.example.com/privkey.pem}%"
#certificate.default.default = true
#
# Step 2: mkdir -p /opt/stalwart/etc/certs/mail.example.com
# Step 3: copy this script to your acme.sh/deploy directory
#
# Author: J Dunphy 8/15/2025
#

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

  # Restart Stalwart to reload certificates and configuration
  if systemctl is-active --quiet stalwart-mail; then
      systemctl restart stalwart-mail
  fi

  return 0

}
