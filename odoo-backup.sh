#!/bin/bash
if [ -z "$USER" ]; then
    echo "ERROR: Instalation error, USER is not defined"
    exit 1
fi
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, USER is not defined"
    exit 1
fi
if [ -z "$HOST" ]; then
    echo "ERROR: Instalation error, HOST is not defined"
    exit 1
fi

NOW=`date '+%Y%m%d_%H%M%S'`
FILESTORE="$HOME/data/filestore"

database="$1"
if [ -z "$database" ]; then
    echo "ERROR: No database"
    echo "Usage: $0 <database>"
    exit 1
fi

mkdir -p $HOME/backup
cd $HOME/backup
/usr/bin/pg_dump -Fc -v -U "$USER" -W --host $HOST -f "${NOW}-${database}.dump" "$database"
/bin/tar -czf "${NOW}-${database}.tar.gz" -C $HOME "$FILESTORE/$database"
