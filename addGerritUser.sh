#!/bin/bash
set -e

HTTP_UID=${GERRIT_ADMIN_UID:-$1}
HTTP_PWD=${GERRIT_ADMIN_PWD:-$2}
GERRIT_URL=${GERRIT_URL:-$3}
SSH_KEY_DIR=${GERRIT_ADMIN_SSH_KEY_DIR:-~/.ssh/id_rsa.pub}
# Do first time login.
RESPONSE=$(curl -X POST -d "username=${HTTP_UID}" -d "password=${HTTP_PWD}" http://${GERRIT_URL}:8080/login 2>/dev/null)
[ -z "${RESPONSE}" ] || { echo "${RESPONSE}" ; exit 1; }

# Add ssh-key
cat "${SSH_KEY_DIR}" | curl --data @- --user "${HTTP_UID}:${HTTP_PWD}"  http://${GERRIT_URL}:8080/a/accounts/self/sshkeys

