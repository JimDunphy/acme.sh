#!/usr/bin/bash

# Zimbra Assumptions:
#    1) acme.sh is installed as zextras
#    2) see: https://wiki.zimbra.com/wiki/index.php?curid=2441

########  Public functions #####################

#domain keyfile certfile cafile fullchain
carbonio_deploy() {
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

   # where we will save root pem
   ISG_X1="$(dirname "$_cca")/../ISG_X1.pem"
   _debug ISG_X1 "$ISG_X1"

   # grab it if we don't have it
   if [ ! -f "$ISG_X1" ]; then
      _debug No "$ISG_X1"
      wget -q "https://letsencrypt.org/certs/isrgrootx1.pem.txt" -O "$ISG_X1" || return 1
   fi

   # append root and walk and verify the chain
   cat "$_cfullchain" "$(dirname "$_cca")/../ISG_X1.pem" > "${_cca}.real"
   /opt/zextras/bin/zmcertmgr verifycrt comm "$_ckey" "$_ccert" "${_cca}.real" || return 1

   #if it verifies we can deploy it
   /bin/logger -p local2.info NETWORK "Certificate has been Renewed for $_cdomain"
   cp -f "$_ckey" /opt/zextras/ssl/carbonio/commercial/commercial.key
   /opt/zextras/bin/zmcertmgr deploycrt comm "$_ccert" "${_cca}.real" || return 1
   #/opt/zextras/bin/ldap restart
   #/opt/zextras/bin/zmmailboxdctl reload
   #/opt/zextras/bin/zmproxyctl reload
   #/opt/zextras/bin/zmmtactl reload
   /opt/zextras/bin/zmcontrol restart
   return 0
}

