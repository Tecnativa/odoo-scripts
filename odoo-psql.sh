#!/bin/bash
if [ -z "$USER" ]; then
    echo "ERROR: Instalation error, USER is not defined"
    exit 1
fi

if [ -z "$HOST" ]; then
    echo "ERROR: Instalation error, HOST is not defined"
    exit 1
fi

database=template1
if [ -n "$1" ] && [[ $1 != -* ]]; then
   database=$1
   shift
fi

exec /usr/bin/psql -h $HOST -U $USER -W $database $@
