#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

#Nothing to do here... I send latest startup script and config on each start.
#Will keep this file in place in case there is eventually some first-run config to be done.  That rhymed.










