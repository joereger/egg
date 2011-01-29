#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APPDIR=$2

ssh -t -t $HOST "sudo ./egg/$APPDIR/tomcat/bin/startup.sh"