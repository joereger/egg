#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

mysqlcheck=`ssh $HOST "[ -e /etc/my.cnf ] && echo 1"`
if [ "$mysqlcheck" == 1 ]; then

    ./log-status.sh "Stopping MySQL on $HOST"
    ssh -t -t $HOST "sudo /sbin/service mysqld stop"
    ./log-status.sh "Sleeping 10 while MySQL shuts down"
    sleep 10

else

    ./log-status.sh "MySQL not found on $HOST, not stopping"

fi



