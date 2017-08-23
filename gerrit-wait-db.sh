#!/usr/bin/env bash

wait_for_database() {
  echo "Waiting for database connection $1:$2 ..."
  until nc -z $1 $2; do
    sleep 2
  done
}

case "${DATABASE_TYPE}" in
  postgresql) wait_for_database "${DB_PORT_5432_TCP_ADDR}" "${DB_PORT_5432_TCP_PORT}"
              ;;
  mysql)      wait_for_database "${DB_PORT_3306_TCP_ADDR}" "${DB_PORT_3306_TCP_PORT}"
              ;;
  *)
              ;;
esac
