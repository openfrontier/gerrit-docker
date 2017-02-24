#!/bin/bash
GERRIT_NAME=${GERRIT_NAME:-gerrit}
GERRIT_VOLUME=${GERRIT_VOLUME:-gerrit-volume}
PG_GERRIT_NAME=${PG_GERRIT_NAME:-pg-gerrit}
docker stop ${GERRIT_NAME}
docker rm -v ${GERRIT_NAME}
docker volume rm ${GERRIT_VOLUME}
docker stop ${PG_GERRIT_NAME}
docker rm -v ${PG_GERRIT_NAME}
docker volume rm pg-gerrit-volume
