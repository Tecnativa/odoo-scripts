#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

if [ -d $HOME/OCB/.git ]; then
    exec $HOME/OCB/odoo.py --config=$HOME/odoo-server.conf --unaccent $@
elif [ -d $HOME/odoo/.git ]; then
    exec $HOME/odoo/odoo.py --config=$HOME/odoo-server.conf --unaccent $@
elif [ -d $HOME/openerp/.git ]; then
    exec $HOME/openerp/openerp-server --config=$HOME/openerp-server.conf --unaccent $@
else
    echo "ERROR: No Odoo repository found"
    exit 2
fi
