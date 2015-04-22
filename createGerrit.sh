#!/bin/bash
set -e
GERRIT_URL=${GERRIT_URL:-$1}
LDAP_SERVER=${LDAP_SERVER:-$2}
LDAP_ACCOUNTBASE=${LDAP_ACCOUNTBASE:-$3}
GERRIT_NAME=${GERRIT_NAME:-gerrit}
PG_GERRIT_NAME=${PG_GERRIT_NAME:-pg-gerrit}
DOCKER_IMAGE=openfrontier/gerrit
LOCAL_VOLUME=~/gerrit_volume
docker run --name $PG_GERRIT_NAME -p 5432:5432 -e POSTGRES_USER=gerrit2 -e POSTGRES_PASSWORD=gerrit -e POSTGRES_DB=reviewdb -d postgres
sleep 5
mkdir -p "${LOCAL_VOLUME}"
docker run --name $GERRIT_NAME --link $PG_GERRIT_NAME:db -p 8080:8080 -p 29418:29418 -v ${LOCAL_VOLUME}:/var/gerrit/review_site -e WEBURL=http://${GERRIT_URL}:8080 -e DATABASE_TYPE=postgresql -e AUTH_TYPE=LDAP -e LDAP_SERVER=${LDAP_SERVER} -e LDAP_ACCOUNTBASE="${LDAP_ACCOUNTBASE}" -d ${DOCKER_IMAGE}

