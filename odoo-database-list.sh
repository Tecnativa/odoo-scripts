#!/bin/bash
if [ -z "$USER" ]; then
    echo "ERROR: Instalation error, USER is not defined"
    exit 1
fi
if [ -z "$HOST" ]; then
    echo "ERROR: Instalation error, HOST is not defined"
    exit 1
fi

read -s -p "Enter DB Password for user '$USER': " db_password
echo

PGPASSWORD="$db_password" /usr/bin/psql -h $HOST -U "$USER" -l -F'|' -A "template1" | grep "|$USER|" | cut -d'|' -f1
