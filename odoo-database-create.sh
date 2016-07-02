#!/bin/bash
if [ -z "$USER" ]; then
    echo "ERROR: Instalation error, USER is not defined"
    exit 1
fi
if [ -z "$HOST" ]; then
    echo "ERROR: Instalation error, HOST is not defined"
    exit 1
fi

database="$1"
if [ -z "$database" ]; then
    echo "ERROR: No database"
    echo "Usage: $0 <database>"
    exit 1
fi

read -s -p "Enter DB Password for user '$USER': " db_password
echo

PGPASSWORD="$db_password" /usr/bin/psql -h $HOST -U "$USER" template1 -c "CREATE DATABASE \"$database\" WITH OWNER \"$USER\""
