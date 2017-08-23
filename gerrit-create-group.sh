#!/usr/bin/env bash

set -e

# Usage
usage() {
    echo "Usage:"
    echo "    ${0} -A <ADMIN_USER> -P <ADMIN_PASSWORD> -g <GROUP_NAME>"
    exit 1
}

# Constants
SLEEP_TIME=10
MAX_RETRY=10

while getopts "A:P:g:" opt; do
  case "${opt}" in
    A)
      admin_user=${OPTARG}
      ;;
    P)
      admin_password=${OPTARG}
      ;;
    g)
      target_group=${OPTARG}
      ;;
    *)
      echo "Invalid parameter(s) or option(s)."
      usage
      ;;
  esac
done

# Validate options
if [ -z "${admin_user}" ] || [ -z "${admin_password}" ] || [ -z "${target_group}" ]; then
    echo "Parameters missing"
    usage
fi

echo "Testing Gerrit Connection"
until curl --location --output /dev/null --silent --write-out "%{http_code}\\n" "http://localhost:8080/gerrit/login" | grep "401" &> /dev/null
do
    echo "Gerrit unavailable, sleeping for ${SLEEP_TIME}"
    sleep "${SLEEP_TIME}"
done

# Check exists
target_group=$(echo -e "${target_group}" | sed 's/ /%20/g')
ret=$(curl --user "${admin_user}:${admin_password}" --output /dev/null --silent --write-out "%{http_code}" "http://localhost:8080/gerrit/a/groups/${target_group}")
if [[ ${ret} -eq 200 ]] ; then
    echo "Group already exists: ${target_group}"
    exit 0
fi

# Add group
echo "Creating group: ${target_group}"
count=0
until [ $count -ge ${MAX_RETRY} ]
do
  ret=$(curl --request PUT --user "${admin_user}:${admin_password}" --output /dev/null --silent --write-out "%{http_code}" http://localhost:8080/gerrit/a/groups/"${target_group}")
  if [[ ${ret} -eq 201 ]]; then
    echo "Group ${target_group} was created"
    break
  fi
  echo "Unable to create group ${target_group}, response code ${ret}, retry ... ${count}"
  count=$((count+1))
  sleep ${SLEEP_TIME}
done
