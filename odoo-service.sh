#!/bin/bash
if [ -z "$USER" ]; then
    echo "ERROR: Instalation error, USER is not defined"
    exit 1
fi

op='status'
if [ -n "$1" ]; then
    op=$1
fi

if [ "$op" != 'status' ]; then
    sudo service $USER $op
    sleep 2
fi
ps ax | grep python | grep odoo
