#!/bin/bash
set -e
GERRIT_WEBURL=${GERRIT_WEBURL:-$1}
LDAP_SERVER=${LDAP_SERVER:-$2}
LDAP_ACCOUNTBASE=${LDAP_ACCOUNTBASE:-$3}
HTTPD_LISTENURL=${HTTPD_LISTENURL:-http://*:8080}
GERRIT_NAME=${GERRIT_NAME:-gerrit}
PG_GERRIT_NAME=${PG_GERRIT_NAME:-pg-gerrit}
GERRIT_IMAGE_NAME=${GERRIT_IMAGE_NAME:-openfrontier/gerrit}
LOCAL_VOLUME=~/gerrit_volume${SUFFIX}

docker run \
--name ${PG_GERRIT_NAME} \
-P \
-e POSTGRES_USER=gerrit2 \
-e POSTGRES_PASSWORD=gerrit \
-e POSTGRES_DB=reviewdb \
-d postgres

while [ -z "$(docker logs ${PG_GERRIT_NAME} 2>&1 | grep 'autovacuum launcher started')" ]; do
    echo "Waiting postgres ready."
    sleep 5
done

mkdir -p "${LOCAL_VOLUME}"

docker run \
--name ${GERRIT_NAME} \
--link ${PG_GERRIT_NAME}:db \
-p 29418:29418 \
-v ${LOCAL_VOLUME}:/var/gerrit/review_site \
-e WEBURL=${GERRIT_WEBURL} \
-e HTTPD_LISTENURL=${HTTPD_LISTENURL} \
-e DATABASE_TYPE=postgresql \
-e AUTH_TYPE=LDAP \
-e LDAP_SERVER=${LDAP_SERVER} \
-e LDAP_ACCOUNTBASE=${LDAP_ACCOUNTBASE} \
-d ${GERRIT_IMAGE_NAME}

