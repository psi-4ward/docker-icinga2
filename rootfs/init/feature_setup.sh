#!/bin/bash
# Enable Icinga2 Features
set -e

ENABLED_FEATURES=$(icinga2 feature list | grep "Enabled features" | cut -d: -f 2)

for f in ${ICINGA_FEATURES} ; do
  echo ${ENABLED_FEATURES} | grep api -q && continue; # feature already enabled

  # Icinga2 api setup
  if [ "${f}" == "api" ] && [ ! -e /etc/icinga2/features-enabled/api.conf ] ; then
    icinga2 api setup
    if [ ! -e /etc/icinga2/conf.d/api-user-icingaweb2.conf ] ; then
      # Create api user for Icingaweb2
      cp /temp/api-user-icingaweb2.conf /etc/icinga2/conf.d/api-user-icingaweb2.conf
      sed -r -i \
        "s/^[ \t\/]*password = .*/  password = \"${ICINGA_API_PASS}\",/g" \
        /etc/icinga2/conf.d/api-user-icingaweb2.conf
    fi

  # Other features
  else
    icinga2 feature enable ${f}
  fi
done



