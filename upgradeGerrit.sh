#!/bin/bash
set -e
GERRIT_WEBURL=${GERRIT_WEBURL:-$1}
LDAP_SERVER=${LDAP_SERVER:-$2}
LDAP_ACCOUNTBASE=${LDAP_ACCOUNTBASE:-$3}
SMTP_SERVER=${SMTP_SERVER:-$4}
USER_EMAIL=${USER_EMAIL:-$5}
SMTP_USER=${SMTP_USER:$6}
SMTP_PASS=${SMTP_PASS:$7}
HTTPD_LISTENURL=${HTTPD_LISTENURL:-http://*:8080}
GERRIT_NAME=${GERRIT_NAME:-gerrit}
GERRIT_VOLUME=${GERRIT_VOLUME:-gerrit-volume}
PG_GERRIT_NAME=${PG_GERRIT_NAME:-pg-gerrit}
GERRIT_IMAGE_NAME=${GERRIT_IMAGE_NAME:-openfrontier/gerrit}
CI_NETWORK=${CI_NETWORK:-ci-network}

# Stop and Delete gerrit container.
if [ -z "$(docker ps -a | grep ${GERRIT_VOLUME})" ]; then
  echo "${GERRIT_VOLUME} does not exist."
  exit 1
elif [ -z "$(docker ps -a | grep ${PG_GERRIT_NAME})" ]; then
  echo "${PG_GERRIT_NAME} does not exist."
  exit 1
elif [ -n "$(docker ps | grep ${GERRIT_NAME} | grep -v ${PG_GERRIT_NAME})" ]; then
  docker stop ${GERRIT_NAME}
fi
if [ -n "$(docker ps -a | grep ${GERRIT_NAME} | grep -v ${GERRIT_VOLUME} | grep -v ${PG_GERRIT_NAME})" ]; then
  docker rm -v ${GERRIT_NAME}
fi

# Start Gerrit.
docker run \
--name ${GERRIT_NAME} \
--net ${CI_NETWORK} \
-p 29418:29418 \
--volumes-from ${GERRIT_VOLUME} \
-e WEBURL=${GERRIT_WEBURL} \
-e HTTPD_LISTENURL=${HTTPD_LISTENURL} \
-e DATABASE_TYPE=postgresql \
-e AUTH_TYPE=LDAP \
-e LDAP_SERVER=${LDAP_SERVER} \
-e LDAP_ACCOUNTBASE=${LDAP_ACCOUNTBASE} \
-e SMTP_SERVER=${SMTP_SERVER} \
-e SMTP_USER=${SMTP_USER} \
-e SMTP_PASS=${SMTP_PASS} \
-e USER_EMAIL=${USER_EMAIL} \
-e GERRIT_INIT_ARGS='--install-plugin=download-commands' \
--restart=unless-stopped \
-d ${GERRIT_IMAGE_NAME}

