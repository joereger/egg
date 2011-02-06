#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi



HOST=$1

#TODO Check for /conf/mysql/my.cnf.$MYSQLID to see if I have unique settings for this one instance
scp resources/my.cnf ec2-user@$HOST:my.cnf
ssh -t -t $HOST "sudo cp my.cnf /etc/my.cnf"
ssh -t -t $HOST "sudo rm my.cnf"
ssh -t -t $HOST "sudo /sbin/chkconfig mysqld on"







