#!/bin/bash
set -e

# Make sure directories exists (in the volume)
mkdir -p /icinga2/cmd
mkdir -p /icinga2/conf
mkdir -p /icinga2/ssh
mkdir -p /icinga2/lib/api/log
mkdir -p /var/run/icinga2

# Create symlinks
rm -rf /var/run/icinga2/cmd /etc/icinga2 /var/spool/icinga2/.ssh /var/lib/icinga2
ln -sf /icinga2/cmd /var/run/icinga2/cmd
ln -sf /icinga2/conf /etc/icinga2
ln -sf /icinga2/ssh /var/spool/icinga2/.ssh
ln -sf /icinga2/lib /var/lib/icinga2

# Copy default config (if volume is empty)
if [ ! -e /icinga2/conf/icinga2.conf ] ; then
  cp -r /temp/icinga2/* /icinga2/conf
fi

# Run setups
[ -x /init/set-timezone.sh ] && /init/set-timezone.sh
[ -x /init/mysql_setup.sh ] && /init/mysql_setup.sh
[ -x /init/feature_setup.sh ] && /init/feature_setup.sh

# Fix ownership
chown icinga /icinga2 -R
chown icinga /var/run/icinga2 -R

# Generate ssh-key for icinga2 user
if [ ! -e /icinga2/ssh/id_rsa ] ; then
  su icinga -c 'ssh-keygen -q -t rsa -N "" -f /icinga2/ssh/id_rsa'
fi

# Run Icinga2 daemon
echo 'Start Icinga2 Daemon'
exec su icinga -c \
  "icinga2 daemon --log-level ${ICINGA_LOGLEVEL:-warning} --include /etc/icinga2"
