#!/usr/bin/env bash

set -e

# Usage
usage() {
    echo "Usage:"
    echo "    ${0} -u <USER> -g <TARGET_GROUP> -A <ADMIN_USER> -P <ADMIN_PASSWORD>"
    exit 1
}

# Constants
SLEEP_TIME=10
MAX_RETRY=10

while getopts "u:g:A:P:" opt; do
  case "${opt}" in
    u)
      username=${OPTARG}
      ;;
    g)
      target_group=${OPTARG}
      ;;
    A)
      admin_user=${OPTARG}
      ;;
    P)
      admin_password=${OPTARG}
      ;;
    *)
      echo "Invalid parameter(s) or option(s)."
      usage
      ;;
  esac
done

# Validate options
if [ -z "${admin_user}" ] || [ -z "${admin_password}" ] || [ -z "${username}" ] || [ -z "${target_group}" ]; then
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
username=$(echo -e "${username}" | sed 's/ /%20/g')
ret=$(curl --user "${admin_user}:${admin_password}" --output /dev/null --silent --write-out "%{http_code}" "http://localhost:8080/gerrit/a/accounts/${username}")
if [[ ${ret} -eq 404 ]] ; then
    echo "User does not exists: ${username}"
    exit 0
fi

target_group=$(echo -e "${target_group}" | sed 's/ /%20/g')
ret=$(curl --user "${admin_user}:${admin_password}" --output /dev/null --silent --write-out "%{http_code}" "http://localhost:8080/gerrit/a/groups/${target_group}")
if [[ ${ret} -eq 404 ]] ; then
    echo "Group does not exists: ${target_group}"
    exit 0
fi

# Add user to group
echo "Adding user: ${username}, to group: ${target_group}"
count=0
until [ $count -ge ${MAX_RETRY} ]
do
  json_request="{ \"members\": [ \"${username}\" ] }"
  ret=$(curl --request POST --user "${admin_user}:${admin_password}" --header 'Content-Type: application/json; charset=UTF-8' --data "${json_request}" --output /dev/null --silent --write-out "%{http_code}" http://localhost:8080/gerrit/a/groups/"${target_group}"/members.add)
  if [[ ${ret} -eq 200 ]]; then
    echo "User ${username} was added to a group ${target_group}"
    break
  fi

  echo "Unable to add user ${username} to a group ${target_group}, response code ${ret}, retry ... ${count}"
  count=$((count+1))
  sleep ${SLEEP_TIME}
done
