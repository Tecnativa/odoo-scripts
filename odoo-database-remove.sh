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

$HOME/bin/odoo-status
if [ $? -eq 0 ]; then echo "ERROR: Odoo service is running"; exit 3; fi

read -s -p "Enter DB Password for user '$USER': " db_password
echo

if PGPASSWORD="$db_password" /usr/bin/psql -h $HOST -U "$USER" -l -F'|' -A "template1" | grep "|$USER|" | cut -d'|' -f1 | egrep -q "^$database\$"; then
    PGPASSWORD="$db_password" /usr/bin/psql -h $HOST -U "$USER" template1 -c "DROP DATABASE \"$database\""
else
    echo "ERROR: Database '$database' not found for user '$USER'"
    exit 2
fi
