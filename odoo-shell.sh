#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

if [ -z "$ADDONS_PATH" ]; then
    echo "ERROR: Instalation error, ADDONS_PATH is not defined"
    exit 1
fi

if [ -d $HOME/OCB/.git ]; then
    exec $HOME/OCB/odoo.py --addons-path=$ADDONS_PATH shell --config=$HOME/odoo-server.conf --unaccent $@
elif [ -d $HOME/odoo/.git ]; then
    exec $HOME/odoo/odoo.py --addons-path=$ADDONS_PATH shell --config=$HOME/odoo-server.conf --unaccent $@
else
    echo "ERROR: No Odoo repository found"
    exit 2
fi
