#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

./log-status.sh "Stopping Apache $HOST"
ssh -t -t $HOST "sudo /sbin/service httpd stop"
ssh -t -t $HOST "sudo killall -9 httpd"


