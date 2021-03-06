#!/bin/bash

#Here is a script to deploy cert to grafana server.

#returns 0 means success, otherwise error.

########  Public functions #####################

#domain keyfile certfile cafile fullchain
grafana_deploy() {
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

  /bin/logger -p local2.info NETWORK "Certificate has been Renewed for $_cdomain"
  cp -f "$_ckey" /etc/grafana/certs/certkey.key
  cp -f "$_ccert" /etc/grafana/certs/fullchain.cer
  # needs entry /etc/sudoers.d/
  # %thisuser ALL=NOPASSWD:/etc/init.d/grafana-server
  # --- RHEL 6/centos 6 specific (uncomment out)
  #/etc/init.d/grafana-server restart

  return 0

}
