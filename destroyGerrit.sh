#!/bin/bash
GERRIT_NAME=${GERRIT_NAME:-gerrit}
PG_GERRIT_NAME=${PG_GERRIT_NAME:-pg-gerrit}
LOCAL_VOLUME=~/gerrit_volume${SUFFIX}
docker stop $GERRIT_NAME
docker rm -v $GERRIT_NAME
docker stop $PG_GERRIT_NAME
docker rm -v $PG_GERRIT_NAME
rm -rf ${LOCAL_VOLUME}
