#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APP APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APP"; exit; fi
if [ "$3" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APP=$2
APPDIR=$3

#Stop instance if it's running (it prolly is)
./egg-tomcat-stop.sh $HOST $APPDIR

#Delete the instance
ssh -t -t $HOST "rm -rf egg/$APPDIR"

