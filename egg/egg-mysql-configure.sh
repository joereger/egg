#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST MYSQLID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a MYSQLID"; exit; fi


HOST=$1
MYSQLID=$2

#Check for /conf/mysql/mysqlid$MYSQLID.my.cnf to see if I have unique settings for this one instance
MYCNFTOSEND=resources/my.cnf
if [ -e conf/mysql/mysqlid${MYSQLID}.my.cnf ]; then
	echo "conf/mysql/mysqlid${MYSQLID}.my.cnf exists"
    MYCNFTOSEND=conf/mysql/mysqlid${MYSQLID}.my.cnf
else
	echo "conf/mysql/mysqlid${MYSQLID}.my.cnf not found, using default my.cnf"
fi


scp $MYCNFTOSEND ec2-user@$HOST:my.cnf
ssh -t -t $HOST "sudo cp my.cnf /etc/my.cnf"
ssh -t -t $HOST "sudo rm my.cnf"
ssh -t -t $HOST "sudo /sbin/chkconfig mysqld on"







