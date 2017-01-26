#!/bin/sh
# XMPP Notification Script for Icinga2 Services
# Uses sendxmpp for mail delivery
# Date:   2017-01-20
# Author: Christoph Wiechert <wio@psitrax.de>

VERSION=1.0.0

usage() {
  echo "XMPP Notifications for Icinga2 Service Alerts"
  echo
  echo 'Arguments:'
  echo '  --address      Service Hostaddr.    ($address$)'
  echo '  --type         Notification Type    ($notification.type$)'
  echo '  --author       Notification Author  ($notification.author$)'
  echo '  --comment      Comment              ($notification.comment$)'
  echo '  --since        Timestamp            ($service.last_state_change$)'
  echo '  --service      Service Name         ($service.name$)'
  echo '  --host         Service Hostname     ($host.name$)'
  echo '  --msg          Message              ($service.output$)'
  echo '  --to           XMPP Recipient       ($user.xmpp$)'
  echo '  --state        Service State        ($service.state$)'
  echo '  --icingaweb    URL of Icingaweb2    =http://$hostname'
  echo '  --xmpp-server  XMPP-Server'
  echo '  --xmpp-user    Username'
  echo '  --xmpp-pass    Passowrd'
  echo '  --xmpp-tls     Enable TLS            =yes'
  echo
  echo 'Legend   =default; ($val$) possible Icinga2 variable'
  echo "Version  $VERSION"
  echo "Author   Christoph Wiechert <wio@psitrax.de>"
}

function err() {
  >&2 echo $1
  exit 1
}

which sendxmpp &>/dev/null || err "ERROR: sendxmpp not found in $PATH"
[ $# -le 0 ] && usage && exit 1

# defaults
XMPP_TLS=${XMPP_TLS:-yes}
ICINGAWEB=${ICINGAWEB:-http://`hostname`}

# parse arguments
while [[ $# -ge 1 ]] ; do
  arg="$1"
  echo $arg: $2
  case $arg in
    --address)      ADDRESS="$2";      shift ;;
    --author)       AUTHOR="$2";       shift ;;
    --comment)      COMMENT="$2";      shift ;;
    --since)        SINCE="$2";        shift ;;
    --service)      SERVICE="$2";      shift ;;
    --from)         FROM="$2";         shift ;;
    --host)         HOST="$2";         shift ;;
    --msg)          MSG="$2";          shift ;;
    --to)           TO="$2";           shift ;;
    --type)         TYPE="$2";         shift ;;
    --state)        STATE="$2";        shift ;;
    --icingaweb)    ICINGAWEB="$2";    shift ;;
    --xmpp-server)  XMPP_SERVER="$2";  shift ;;
    --xmpp-user)    XMPP_USER="$2";    shift ;;
    --xmpp-pass)    XMPP_PASS="$2";    shift ;;
    --xmpp-tls)     XMPP_TLS="$2";     shift ;;

    -v|--version) echo $VERSION; exit 0 ;;
    -h|--help) usage ; exit 0 ;;
    *) err "ERROR: Invalid argument $arg" ;;
  esac
  shift
done


urlencode() {
  old_lc_collate=$LC_COLLATE
  LC_COLLATE=C
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
      *) printf '%%%02X' "'$c" ;;
    esac
  done
  LC_COLLATE=$old_lc_collate
}

[ -n "$COMMENT" ] && COMMENT="Comment by $AUTHOR: $COMMENT\n"
[ -n "$AUTHOR" ] && FROM="$AUTHOR <$FROM>"
[ -n "$SINCE" ] && SINCE=$(date --date=@$SINCE)

BODY=`cat <<EOF
$SERVICE on $HOST is $STATE!

$MSG

Since: $SINCE
$COMMENT
$ICINGAWEB/monitoring/service/show?host=$(urlencode $HOST)&service=$(urlencode $SERVICE)
EOF
`

ARGS="-u $XMPP_USER -j $XMPP_SERVER -p $XMPP_PASS $TO"
[ "$XMPP_TLS" = "yes" ] && ARGS="-t $ARGS"


/usr/bin/printf "%b" "$BODY" | sendxmpp $ARGS
