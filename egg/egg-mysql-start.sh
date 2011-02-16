#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

./log-status.sh "Starting MySQL on $HOST"
ssh -t -t $HOST "sudo /sbin/service mysqld start"

