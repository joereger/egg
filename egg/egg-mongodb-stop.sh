#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1



    ./log-status.sh "Stopping MONGODB on $HOST"
    ssh -t -t $HOST "sudo kill -2 `ps aux | grep [m]ongo* | awk '{ print $2 }'`"
    ./log-status.sh "Sleeping 10 while MONGODB shuts down"
    sleep 10




