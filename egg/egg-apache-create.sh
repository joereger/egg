#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi


HOST=$1

./egg-apache-stop.sh $HOST
ssh $HOST "sudo yum -y install httpd"
ssh $HOST "sudo /sbin/chkconfig httpd on"
ssh $HOST "cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.original"
./egg-apache-configure.sh $HOST
./egg-apache-start.sh $HOST
