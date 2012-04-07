#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi


HOST=$1

./egg-apache-stop.sh $HOST
./log-status.sh "Creating Apache $HOST"
ssh -t -t $HOST "sudo yum -y install httpd"
ssh -t -t $HOST "sudo yum -y install mod_ssl"
ssh -t -t $HOST "sudo /sbin/chkconfig httpd on"
ssh -t -t $HOST "sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.original"

