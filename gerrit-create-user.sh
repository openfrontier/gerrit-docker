#!/bin/bash
set -e

# Usage
usage() {
    echo "Usage:"
    echo "    ${0} -t <ACOUNT_TYPE:ldap or internal> -u <USER> -p <PASSWORD> -f <FULL_NAME> -A <ADMIN_USER> -P <ADMIN_PASSWORD>"
    exit 1
}

# Constants
SLEEP_TIME=10
MAX_RETRY=10

while getopts "t:u:p:f:A:P:" opt; do
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
until curl --silent --location --write-out "%{http_code}\\n" --output /dev/null "http://localhost:8080/gerrit/login" | grep "401" &> /dev/null
do
    echo "Gerrit unavailable, sleeping for ${SLEEP_TIME}"
    sleep "${SLEEP_TIME}"
done

# Check exists
ret=$(curl --location --output /dev/null --silent --write-out "%{http_code}\\n" "http://localhost:8080/gerrit/accounts/${username}")
if [[ ${ret} -eq 200 ]] ; then
    echo "User already existed: ${username}"
    exit 0
fi

# Add user
echo "Creating user: ${username}"
count=0
until [ $count -ge ${MAX_RETRY} ]
do
  case "${type}" in
    ldap)
      ret=$(curl --request POST --data "username=${username}&password=${password}" --write-out "%{http_code}" --silent --output /dev/null http://localhost:8080/gerrit/login)
      [[ ${ret} -eq 302  ]] && break
      ;;
    internal)
      json_request="{ \"name\": \""${full_name}"\", \"groups\": [ \"Non-Interactive Users\" ] }"
      ret=$(curl --request PUT --user "${admin_user}:${admin_password}" --header 'Content-Type: application/json; charset=UTF-8' --data "${json_request}" --write-out "%{http_code}" --silent --output /dev/null http://localhost:8080/gerrit/a/accounts/${username})
      [[ ${ret} -eq 201 ]] && break
      ;;
  esac

  echo "Unable to create user ${username}, response code ${ret}, retry ... ${count}"
  count=$[$count+1]
  sleep ${SLEEP_TIME}
done
