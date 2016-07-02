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

FILESTORE="$HOME/data/filestore"

file="$1"
FILE_DB="$file.dump"
FILE_TAR="$file.tar.gz"

database="$2"

show_help(){
   echo "ERROR: $1"
   echo "Usage: $0 <backup_file> <new_database_name>"
   exit 1
}

if [ -z "$file" ]; then show_help "No filename selected"; fi
if [ -z "$database" ]; then show_help "No database name defined"; fi
if [ ! -f "$FILE_DB" ]; then echo "Database file '$FILE_DB' not found"; exit 2; fi
if [ ! -f "$FILE_TAR" ]; then echo "Filestore file '$FILE_TAR' not found"; exit 2; fi

$HOME/bin/odoo-status
if [ $? -eq 0 ]; then echo "ERROR: Odoo service is running"; exit 3; fi

FILE_DB_PATH=`realpath "$FILE_DB"`
FILE_TAR_PATH=`realpath "$FILE_TAR"`
ORIGINAL_DB=`echo "$file" | cut -c 17-`
read -s -p "Enter DB Password for user '$USER': " db_password

echo "Removing database: $database"
PGPASSWORD="$db_password" /usr/bin/psql -h $HOST -U "$USER" template1 -c "DROP DATABASE \"$database\""
error=$?; if [ $error -ne 0 ]; then echo "ERROR: $error"; fi

echo "Create database: $database"
PGPASSWORD="$db_password" /usr/bin/psql -h $HOST -U "$USER" template1 -c "CREATE DATABASE \"$database\" WITH OWNER \"$USER\""
error=$?; if [ $error -ne 0 ]; then echo "ERROR: $error"; fi

echo "Restoring database: $database"
PGPASSWORD="$db_password" /usr/bin/pg_restore --username "$USER" --host $HOST --dbname "$database" --no-owner "$FILE_DB"
error=$?; if [ $error -ne 0 ]; then echo "ERROR: $error"; fi

echo "Remove filestore"
rm -rf "$FILESTORE/$database"

echo "Restore filestore"
cd $HOME
/bin/tar -xzf "$FILE_TAR_PATH"

if [ "$ORIGINAL_DB" != "$database" ]; then
    echo "Rename filestore: $ORIGINAL_DB -> $database"
    mv "$FILESTORE/$ORIGINAL_DB" "$FILESTORE/$database"
fi
