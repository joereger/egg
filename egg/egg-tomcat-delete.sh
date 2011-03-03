#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APPDIR=$2

#Stop instance if it's running (it prolly is)
./egg-tomcat-stop.sh $HOST $APPDIR

#Delete the instance
ssh -t -t $HOST "sudo rm -rf egg/$APPDIR"

