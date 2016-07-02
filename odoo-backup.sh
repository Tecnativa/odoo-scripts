#!/bin/bash
if [ -z "$USER" ]; then
    echo "ERROR: Instalation error, USER is not defined"
    exit 1
fi
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi
if [ -z "$HOST" ]; then
    echo "ERROR: Instalation error, HOST is not defined"
    exit 1
fi
if [ -z "$FILESTORE" ]; then
    echo "ERROR: Instalation error, FILESTORE is not defined"
    exit 1
fi

NOW=`date '+%Y%m%d_%H%M%S'`

database="$1"
if [ -z "$database" ]; then
    echo "ERROR: No database"
    echo "Usage: $0 <database>"
    exit 1
fi

logfile="${NOW}-${database}-backup.log"

mkdir -p $HOME/backup
cd $HOME/backup
echo "BACKUP: DATABASE = $database, TIME = $NOW" > $logfile
read -s -p "Enter DB Password for user '$USER': " db_password
echo

if ! PGPASSWORD="$db_password" /usr/bin/psql -h $HOST -U "$USER" -l -F'|' -A "template1" | grep "|$USER|" | cut -d'|' -f1 | egrep -q "^$database\$"; then
    echo "ERROR: Database '$database' not found for user '$USER'"
    exit 2
fi

if [ ! -d "$HOME/$FILESTORE/$database" ]; then
    echo "ERROR: Filestore '$HOME/$FILESTORE/$database' not found"
    exit 3
fi

echo -n "Backup database: $database ... "
PGPASSWORD="$db_password" /usr/bin/pg_dump -Fc -v -U "$USER" --host $HOST -f "${NOW}-${database}.dump" "$database" >> $logfile 2>&1
error=$?; if [ $error -eq 0 ]; then echo "OK"; else echo "ERROR: $error"; fi

echo -n "Backup filestore: $FILESTORE/$database ... "
/bin/tar -czf "${NOW}-${database}.tar.gz" -C $HOME "$FILESTORE/$database" >> $logfile 2>&1
error=$?
if [ $error -eq 0 ]; then echo "OK"; else echo "ERROR: $error"; fi
