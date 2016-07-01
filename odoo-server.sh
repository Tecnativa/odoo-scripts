#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

exec $HOME/OCB/odoo.py --config=$HOME/odoo-server.conf --unaccent \$@
