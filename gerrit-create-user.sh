#!/usr/bin/env bash

set -e

# Usage
usage() {
    echo "Usage:"
    echo "    ${0} -t <ACOUNT_TYPE:ldap or internal> -u <USER> -p <PASSWORD> -f <FULL_NAME> -A <ADMIN_USER> -P <ADMIN_PASSWORD> -g <TARGET_GROUP>"
    exit 1
}

# Constants
SLEEP_TIME=10
MAX_RETRY=10

type="internal"

while getopts "t:u:p:f:A:P:g:" opt; do
  case "${opt}" in
    t)
      type=${OPTARG}
      ;;
    u)
      username=${OPTARG}
      ;;
    p)
      password=${OPTARG}
      ;;
    f)
      full_name=${OPTARG}
      ;;
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
case "${type}" in
  ldap)
      if [ -z "${username}" ] || [ -z "${password}" ]; then
          echo "Parameters missing"
          usage
      fi
      ;;
  internal)
      if [ -z "${admin_user}" ] || [ -z "${admin_password}" ] || [ -z "${username}" ] || [ -z "${full_name}" ]; then
          echo "Parameters missing"
          usage
      fi
      ;;
  *)
      echo "Invalid parameter(s) or option(s)."
      usage
      ;;
esac

echo "Testing Gerrit Connection"
until curl --location --output /dev/null --silent --write-out "%{http_code}\\n" "http://localhost:8080/gerrit/login" | grep "401" &> /dev/null
do
    echo "Gerrit unavailable, sleeping for ${SLEEP_TIME}"
    sleep "${SLEEP_TIME}"
done

# Check exists
username=$(echo -e "${username}" | sed 's/ /%20/g')
ret=$(curl --output /dev/null --silent --write-out "%{http_code}" "http://localhost:8080/gerrit/accounts/${username}")
if [[ ${ret} -eq 200 ]] ; then
    echo "User already exists: ${username}"
    exit 0
fi

# Add user
echo "Creating user: ${username}"
count=0
until [ $count -ge ${MAX_RETRY} ]
do
  case "${type}" in
    ldap)
      ret=$(curl --request POST --data "username=${username}&password=${password}" --output /dev/null --silent --write-out "%{http_code}" http://localhost:8080/gerrit/login)
      if [[ ${ret} -eq 302 ]]; then
        echo "LDAP user ${username} was found in database"
        break
      fi
      echo "Unable to find user ${username} in LDAP database, response code ${ret}, retry ... ${count}"
      ;;
    internal)
      if [[ -z "${target_group}" ]]; then
        target_group="Non-Interactive Users"
        echo "Target group was not specified, defaulting to non-interactive"
      fi
      json_request="{ \"name\": \"${full_name}\", \"groups\": [ \"${target_group}\" ] }"
      ret=$(curl --request PUT --user "${admin_user}:${admin_password}" --header 'Content-Type: application/json; charset=UTF-8' --data "${json_request}" --output /dev/null --silent --write-out "%{http_code}" http://localhost:8080/gerrit/a/accounts/"${username}")
      if [[ ${ret} -eq 201 ]]; then
        echo "User ${username} was created"
        break
      fi
      echo "Unable to create user ${username}, response code ${ret}, retry ... ${count}"
      ;;
  esac
  count=$((count+1))
  sleep ${SLEEP_TIME}
done
