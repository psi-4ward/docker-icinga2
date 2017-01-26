#!/bin/bash

# Setup ido-mysql.conf
if $MYSQL_AUTOCONF ; then
  sed -r -i "s/^[ \t\/]*user = .*/  user = \"${MYSQL_USER}\",/g" /etc/icinga2/features-available/ido-mysql.conf
  sed -r -i "s/^[ \t\/]*password = .*/  password = \"${MYSQL_PASS}\",/g" /etc/icinga2/features-available/ido-mysql.conf
  sed -r -i "s/^[ \t\/]*host = .*/  host = \"${MYSQL_HOST}\",/g" /etc/icinga2/features-available/ido-mysql.conf
  sed -r -i "s/^[ \t\/]*port = .*/  port = \"${MYSQL_PORT}\",/g" /etc/icinga2/features-available/ido-mysql.conf
  sed -r -i "s/^[ \t\/]*database = .*/  database = \"${MYSQL_DB}\",/g" /etc/icinga2/features-available/ido-mysql.conf
fi

MYSQLCMD="mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASS -r -N"

# Wait for Database to come up
isDBup () {
  echo "SHOW STATUS" | $MYSQLCMD 1>/dev/null
  echo $?
}
RETRY=10
until [ `isDBup` -eq 0 ] || [ $RETRY -le 0 ] ; do
  echo "Waiting for database to come up"
  sleep 5
  RETRY=$(expr $RETRY - 1)
done
if [ $RETRY -le 0 ]; then
  >&2 echo Error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT
  exit 1
fi


# Create database if necessary
echo "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;" | $MYSQLCMD || exit $?
MYSQLCMD="$MYSQLCMD $MYSQL_DB"

# Version compare function
vercomp () {
    if [[ $1 == $2 ]] ; then
        echo '=' ; return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)) ; do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)) ; do
        if [[ -z ${ver2[i]} ]] ; then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})) ; then
            echo '>' ; return 0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})) ; then
            echo '<' ; return 0
        fi
    done
    echo '='
}

# Init/Update database scheme if necessary
if [ "$(echo "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = \"$MYSQL_DB\";" | $MYSQLCMD)" -le 1 ]; then
  echo Initializing Database Schema
  cat /usr/share/icinga2-ido-mysql/schema/mysql.sql | $MYSQLCMD || exit $?
else
  VER=$(echo "SELECT version FROM icinga_dbversion WHERE name='idoutils'" | ${MYSQLCMD})
  for DB_UPDATE_FILE in $(ls -1 /usr/share/icinga2-ido-mysql/schema/upgrade) ; do
    FILE_VER=$(grep 'INSERT INTO icinga_dbversion' /usr/share/icinga2-ido-mysql/schema/upgrade/${DB_UPDATE_FILE} | grep -oP '\d+\.\d+\.\d+' | head -n1)
    if [ "`vercomp $VER $FILE_VER`" = "<" ] ; then
      echo Apply Database Update ${FILE_VER} from ${DB_UPDATE_FILE}
      cat /usr/share/icinga2-ido-mysql/schema/upgrade/${DB_UPDATE_FILE} | ${MYSQLCMD} || exit $?
    fi
  done
fi
