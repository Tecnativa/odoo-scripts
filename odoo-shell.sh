#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

if [ -z "$ADDONS_PATH" ]; then
    echo "ERROR: Instalation error, ADDONS_PATH is not defined"
    exit 1
fi

exec $HOME/OCB/odoo.py --addons-path=$ADDONS_PATH shell --config=$HOME/odoo-server.conf --unaccent \$@

#!/bin/bash
