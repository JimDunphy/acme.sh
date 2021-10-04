#!/bin/bash

# Zimbra Assumptions:
#    1) acme.sh is installed as Zimbra
#    2) see: https://wiki.zimbra.com/wiki/JDunphy-Letsencrypt
#    3) --preferred-chain "ISRG" or are using this chain

########  Public functions #####################

#domain keyfile certfile cafile fullchain
zimbra_deploy() {
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

   # Zimbra's still needs CA pem to verify on some versions
   ISG_X1="$(dirname "$_cca")/../ISG_X1.pem"
   _debug ISG_X1 "$ISG_X1"

   # grab root pem if we don't have it
   if [ ! -f "$ISG_X1" ]; then
      _debug No "$ISG_X1"
      wget -q "https://letsencrypt.org/certs/isrgrootx1.pem.txt" -O "$ISG_X1" || return 1
   fi

   # append root pem so verifycrt can walk the chain
   cat "$_cfullchain" "$(dirname "$_cca")/../ISG_X1.pem" > "${_cca}.real"
   /opt/zimbra/bin/zmcertmgr verifycrt comm "$_ckey" "$_ccert" "${_cca}.real" || return 1

   #if it verifies we can deploy it
   $(which logger) -p local2.info NETWORK "Certificate has been Renewed for $_cdomain"
   cp -f "$_ckey" /opt/zimbra/ssl/zimbra/commercial/commercial.key
   /opt/zimbra/bin/zmcertmgr deploycrt comm "$_ccert" "${_cca}.real" || return 1
   #/opt/zimbra/bin/ldap restart
   #/opt/zimbra/bin/zmmailboxdctl reload
   #/opt/zimbra/bin/zmproxyctl reload
   #/opt/zimbra/bin/zmmtactl reload
   /opt/zimbra/bin/zmcontrol restart
   return 0
}
