#!/usr/bin/env bash

set -e

# Usage
usage() {
    echo "Usage:"
    echo "    ${0} -A <username> -P <password> -k <KEY_FOR_USER> -u <FOR_USER>"
    exit 1
}

# Constants configurable via environment
GERRIT_URL=${GERRIT_LOCAL_URL:-'http://localhost:8080/gerrit'}
JENKINS_URL=${JENKINS_REMOTE_URL:-'http://jenkins:8080/jenkins'}

# Constants
SLEEP_TIME=10

while getopts "A:P:k:u:" opt; do
  case "${opt}" in
    A)
      username=${OPTARG}
      ;;
    P)
      password=${OPTARG}
      ;;
    k)
      key=${OPTARG}
      ;;
    u)
      user=${OPTARG}
      ;;
    *)
      echo "Invalid parameter(s) or option(s)."
      usage
      ;;
  esac
done

if [ -z "${username}" ] || [ -z "${password}" ] || [ -z "${key}" ] || [ -z "${user}" ]; then
    echo "Parameters missing"
    usage
fi

key=$(echo -e "${key}" | sed 's/ /%20/g')
user=$(echo -e "${user}" | sed 's/ /%20/g')

echo "Testing Jenkins Connection & Key Presence"
until curl --location --user ${username}:${password} --output /dev/null --silent --write-out "%{http_code}\\n" "${JENKINS_URL}/userContent/${key}" | grep "200" &> /dev/null
do
    echo "Jenkins or key unavailable, sleeping for ${SLEEP_TIME}"
    sleep "${SLEEP_TIME}"
done

echo "Retrieving value: ${key}"
ssh_key=$(curl --silent --request GET --user ${username}:${password} "${JENKINS_URL}/userContent/${key}")

echo "Checking if \"${user}\" exists"
if curl --location --output /dev/null --silent --write-out "%{http_code}\\n" "${GERRIT_URL}/accounts/${user}" | grep "404" &> /dev/null; then
    echo "User does not exist: ${user}"
    exit 1
fi

echo "* Verify public-key existence"
# Download the stored key and decode from to UTF-8
# Using echo -e the -n switch from echo allows to remove the trailing \n that echo would add
# The decode part is necessary as Gerrit correctly encode the SSH key and as a result = sign is converted to \u003d
stored_key=$(echo -e $(curl --user ${username}:${password} --silent "${GERRIT_URL}/a/accounts/${user}/sshkeys" | grep "ssh_public_key" | awk '{split($0, a, ": "); print a[2]}' | sed 's/[",]//g'))
if [[ "$stored_key" == "$ssh_key" ]]; then
  echo "* Stored key is the same as downloaded, skipping it ..."
  exit 0
else
  echo "* Stored key is not same as downloaded, uploading it ..."
fi

echo "Uploading public-key to Gerrit user \"${user}\""
ret=$(curl --request POST --user "${username}:${password}" --data "${ssh_key}" --output /dev/null --silent --write-out "%{http_code}" "${GERRIT_URL}/a/accounts/${user}/sshkeys")
if [[ ${ret} -eq 201 ]]; then
  echo "Public-key was uploaded"
else
  echo "Public-key was uploaded with the invalid response code: ${ret}"
fi
