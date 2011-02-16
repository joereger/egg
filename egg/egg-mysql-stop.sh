#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

#TODO Only make this call if $HOST is actually listed as a MySQL instance... i call this script from egg-instance-terminate.sh

./log-status.sh "Stopping MySQL on $HOST"
ssh -t -t $HOST "sudo /sbin/service mysqld stop"
./log-status.sh "Sleeping 10 while MySQL shuts down"
sleep 10



