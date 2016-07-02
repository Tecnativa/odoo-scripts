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
    sudo systemctl $op $USER.service
    sleep 2
fi
sudo systemctl --no-pager status $USER.service
