#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

DBPASS="catalyst"

HOST=$1


#This is the process of creating a MySQL Install from absolute nothingness
#ssh -t -t $HOST "sudo mysqladmin -u root password '$DBPASS'"
#
#./egg-mysql-stop.sh $HOST
#
#ssh -t -t $HOST "sudo /usr/bin/mysql -u root -p$DBPASS -e \"grant all on *.* to root@'%' identified by '$DBPASS'\""
#
#ssh -t -t $HOST "sudo /usr/bin/mysql -u root -p$DBPASS -e \"DROP DATABASE test\""
#
#ssh -t -t $HOST "sudo /usr/bin/mysql -u root -p$DBPASS -e \"DELETE FROM mysql.user WHERE user = ''\""


#Once I create in the local /var/lib/mysql dir I need to move that install/creds to EBS vol
#I have an EBS volume mounted at /vol
#This /vol directory has a /vol/mysqldata directory.
#That directory contains all of the mysql logs and data files.
#They are created manually and manually populated with the right data
#sudo mkdir /vol/mysqldata
#sudo chown -R mysql:mysql /vol/mysqldata
#sudo cp -r /var/lib/mysql/* /vol/mysqldata
#sudo chown -R mysql:mysql /vol/mysqldata/*

./log.sh "Installing MONGODB on $HOST"
ssh -t -t $HOST "curl http://downloads.mongodb.org/linux/mongodb-linux-x86_64-2.0.4.tgz > mongo.tgz"
ssh -t -t $HOST "tar xzf mongo.tgz"
#ssh -t -t $HOST "sudo mkdir -p /data/db/"
#ssh -t -t $HOST "sudo chown `id -u` /data/db"
ssh -t -t $HOST "sudo mkdir -p /vol/mongodbdata"
ssh -t -t $HOST "sudo chown `id -u` /vol/mongodbdata"
ssh -t -t $HOST "sudo chown `id -u` /vol/mongodbdata/*"

ssh -t -t $HOST "sudo mkdir -p /vol/mongodblog"
ssh -t -t $HOST "sudo chown `id -u` /vol/mongodblog"
ssh -t -t $HOST "sudo chown `id -u` /vol/mongodblog/*"







