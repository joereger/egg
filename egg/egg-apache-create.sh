#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APPDIR=$2

./egg-apache-stop.sh $HOST
ssh $HOST "sudo yum -y install httpd"
ssh $HOST "sudo chkconfig httpd on"
./egg-apache-configure.sh $HOST
./egg-apache-start.sh $HOST
