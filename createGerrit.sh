#!/bin/bash
set -e
GERRIT_WEBURL=${GERRIT_WEBURL:-$1}
LDAP_SERVER=${LDAP_SERVER:-$2}
LDAP_ACCOUNTBASE=${LDAP_ACCOUNTBASE:-$3}
SMTP_SERVER=${SMTP_SERVER:-$4}
USER_EMAIL=${USER_EMAIL:-$5}
SMTP_USER=${SMTP_USER:-$6}
SMTP_PASS=${SMTP_PASS:-$7}
HTTPD_LISTENURL=${HTTPD_LISTENURL:-http://*:8080}
GERRIT_NAME=${GERRIT_NAME:-gerrit}
GERRIT_VOLUME=${GERRIT_VOLUME:-gerrit-volume}
PG_GERRIT_NAME=${PG_GERRIT_NAME:-pg-gerrit}
GERRIT_IMAGE_NAME=${GERRIT_IMAGE_NAME:-openfrontier/gerrit}
POSTGRES_IMAGE=${POSTGRES_IMAGE:-postgres}

# Start PostgreSQL.
docker run \
--name ${PG_GERRIT_NAME} \
-P \
-e POSTGRES_USER=gerrit2 \
-e POSTGRES_PASSWORD=gerrit \
-e POSTGRES_DB=reviewdb \
-d ${POSTGRES_IMAGE}

while [ -z "$(docker logs ${PG_GERRIT_NAME} 2>&1 | grep 'autovacuum launcher started')" ]; do
    echo "Waiting postgres ready."
    sleep 1
done

# Create Gerrit volume.
docker run \
--name ${GERRIT_VOLUME} \
${GERRIT_IMAGE_NAME} \
echo "Create Gerrit volume."

# Start Gerrit.
docker run \
--name ${GERRIT_NAME} \
--link ${PG_GERRIT_NAME}:db \
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
-d ${GERRIT_IMAGE_NAME}

