#!/bin/sh
# Mail Notification Script for Icinga2 Services
# Uses swaks for mail delivery: http://www.jetmore.org/john/code/swaks/
# Date:   2017-01-19
# Author: Christoph Wiechert <wio@psitrax.de>

VERSION=1.0.0

usage() {
  echo "Mail Notifications for Icinga2 Service Alerts"
  echo
  echo 'Arguments:'
  echo '  --address      Service Hostaddr.    ($address$)'
  echo '  --type         Notification Type    ($notification.type$)'
  echo '  --author       Notification Author  ($notification.author$)'
  echo '  --comment      Comment              ($notification.comment$)'
  echo '  --since        Timestamp            ($service.last_state_change$)'
  echo '  --service      Service Name         ($service.name$)'
  echo '  --from         Mail From            =icinga2@hostname'
  echo '  --host         Service Hostname     ($host.name$)'
  echo '  --msg          Message              ($service.output$)'
  echo '  --to           Mail Recipient       ($user.email$)'
  echo '  --state        Service State        ($service.state$)'
  echo '  --icingaweb    URL of Icingaweb2    =http://$hostname'
  echo '  --smtp-server  SMTP-Server          =localhost'
  echo '  --smtp-auth    SMTP-Authtype        =PLAIN'
  echo '                 PLAIN,LOGIN,CRAM-MD5,CRAM-SHA1,DIGEST-MD5'
  echo '  --smtp-user    Username for SMTP-Auth'
  echo '  --smtp-pass    Passowrd for SMTP-Auth'
  echo '  --smtp-sec     SMTP Security: none,SSL,TLS =none'
  echo '  --smtp-port    SMTP Port'
  echo
  echo 'Legend   =default; ($val$) possible Icinga2 variable'
  echo "Version  $VERSION"
  echo "Author   Christoph Wiechert <wio@psitrax.de>"
}

function err() {
  >&2 echo $1
  exit 1
}

which swaks &>/dev/null || err "ERROR: swaks not found in $PATH"
[ $# -le 0 ] && usage && exit 1

# defaults
FROM=${FROM:-icinga2@`hostname`}
SMTP_SERVER=${SMTP_SERVER:-localhost}
SMTP_SEC=${SMTP_SEC:-none}
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
    --smtp-server)  SMTP_SERVER="$2";  shift ;;
    --smtp-auth)    SMTP_AUTH="$2";    shift ;;
    --smtp-user)    SMTP_USER="$2";    shift ;;
    --smtp-pass)    SMTP_PASS="$2";    shift ;;
    --smtp-port)    SMTP_PORT="$2";    shift ;;
    --smtp-sec)     SMTP_SEC="$2";     shift ;;

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

[ -n "$COMMENT" ] && COMMENT="\nComment by $AUTHOR: $COMMENT\n"
[ -n "$AUTHOR" ] && FROM="$AUTHOR <$FROM>"
[ -n "$SINCE" ] && SINCE=$(date --date=@$SINCE)

BODY=`cat <<EOF
$SERVICE on $HOST is $STATE!

Since: $SINCE
Host:  $ADDRESS

$MSG
$COMMENT

$ICINGAWEB/monitoring/service/show?host=$HOST&service=$(urlencode $SERVICE)

EOF
`

MAIL_ARGS=""
[ -n "$SMTP_PORT" ] && MAIL_ARGS="$MAIL_ARGS --port $SMTP_PORT"
[ -n "$SMTP_AUTH" ] && MAIL_ARGS="$MAIL_ARGS --auth $SMTP_AUTH"
[ -n "$SMTP_USER" ] && MAIL_ARGS="$MAIL_ARGS --auth-user $SMTP_USER"
[ -n "$SMTP_PASS" ] && MAIL_ARGS="$MAIL_ARGS --auth-password $SMTP_PASS"
[ -n "$SMTP_USER" ] && [ -z "$SMTP_AUTH" ] && SMTP_AUTH=PLAIN

[ "$SMTP_SEC" = "TLS" ] &&  MAIL_ARGS="$MAIL_ARGS -tls"
[ "$SMTP_SEC" = "SSL" ] &&  MAIL_ARGS="$MAIL_ARGS --protocol SSMTP"
MID=$($RANDOM$RANDOM$RANDOM | md5sum)
MID=${MID:0:16}

/usr/bin/printf "%b" "$BODY" \
  | swaks \
    --h-Subject "$TYPE: $SERVICE@$HOST is $STATE" \
    --add-header "Message-Id: <${MID}$(echo $FROM | grep -oE '@[^>]+')>" \
    --add-header "Content-Type: text/plain; charset=\"UTF-8\"" \
    --add-header "Mime-Version: 1.0" \
    --body - \
    --to "$TO" \
    --from "$FROM" \
    --server $SMTP_SERVER \
    $MAIL_ARGS

