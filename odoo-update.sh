#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

database=$1
if [ -z "$database" ]; then
    echo "ERROR: No database"
    echo "Usage: $0 <database> [module_a[,module_b,...]]"
    exit 2
fi
modules=${2:-all}
exec $HOME/bin/odoo-server -d $database --update=$modules --stop-after-init
