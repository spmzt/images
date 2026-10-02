#!/bin/sh
set -eu

: "${PGDATA:=/var/db/postgres/data18}"
: "${POSTGRES_USER:=postgres}"
export PGDATA

if [ ! -s "${PGDATA}/PG_VERSION" ]; then
	if [ -z "${POSTGRES_PASSWORD:-}" ]; then
		printf "Database is not initialized; set POSTGRES_PASSWORD\n" >&2
		exit 1
	fi

	pwfile=$(mktemp)
	printf "%s\n" "${POSTGRES_PASSWORD}" > "${pwfile}"
	initdb -D "${PGDATA}" -U "${POSTGRES_USER}" --pwfile="${pwfile}" \
	    -E UTF8 --locale=C.UTF-8 \
	    --auth-local=trust --auth-host=scram-sha-256
	rm -f "${pwfile}"

	printf "listen_addresses = '*'\n" >> "${PGDATA}/postgresql.conf"
	printf "host all all all scram-sha-256\n" >> "${PGDATA}/pg_hba.conf"
fi

exec "$@"
