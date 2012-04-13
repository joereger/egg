#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST MMONGODBID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a MMONGODBID"; exit; fi


HOST=$1
MONGODBID=$2

##Check for $CONFDIR/mongodb/mysqlid$MYSQLID.my.cnf to see if I have unique settings for this one instance
#MYCNFTMP=$CONFDIR/mongodb/default.mongo.cnf
#if [ -e $CONFDIR/mongodb/mysqlid${MYSQLID}.mongo.cnf ]; then
#	./log.sh "$CONFDIR/mongodb/mysqlid${MYSQLID}.mongo.cnf exists"
#    MYCNFTMP=$CONFDIR/mongodb/mysqlid${MYSQLID}.mongo.cnf
#else
#	./log.sh "$CONFDIR/mongodb/mysqlid${MYSQLID}.mongo.cnf not found, using default mongo.cnf"
#fi
#
##Copy to data
#MYCNFLOCAL=data/mongoid${MONGODBID}.mongo.cnf.local
#MYCNFREMOTE=data/mongoid${MONGODBID}.mongo.cnf.remote
#cp $MYCNFTMP $MYCNFLOCAL


#Download the latest remote file
#rm -f $MYCNFREMOTE
#scp ec2-user@$HOST:/etc/my.cnf $MYCNFREMOTE

#
##Determine whether this new config is different than the latest
#if  diff $MYCNFLOCAL $MYCNFREMOTE >/dev/null ; then
#    ./log.sh "mongodb$MONGODBID mongo.cnf remote is SAME as local"
#    ./pulse-update.sh "MONGODB$MONGODBID" "MONGO.CNF REMOTE SAME AS LOCAL"
#else
#    ./log.sh "mongodbid$MONGODBID mongo.cnf remote is DIFFERENT than local"
#    ./pulse-update.sh "MONGODB$MONGODBID" "MONGO.CNF REMOTE DIFFERENT THAN LOCAL"
#
#    #Copy latest to the remote Apache host
#    scp $MYCNFLOCAL ec2-user@$HOST:my.cnf
#    ssh -t -t $HOST "sudo cp my.cnf /etc/my.cnf"
#    ssh -t -t $HOST "sudo rm my.cnf"
#    ssh -t -t $HOST "sudo /sbin/chkconfig mysqld on"
#
#    #Make sure we have the latest locally
#    scp ec2-user@$HOST:/etc/my.cnf $MYCNFREMOTE
#
#    #Bounce MySQL
#    ./pulse-update.sh "MONGODB$MONGODBID" "BOUNCING MONGODB, STOPPING"
#    ./egg-mysql-stop.sh $HOST
#    ./pulse-update.sh "MONGODB$MONGODBID" "BOUNCING MONGODB, STARTING"
#    ./egg-mysql-start.sh $HOST
#    ./pulse-update.sh "MONGODB$MONGODBID" "DONE BOUNCING MONGODB"
#fi





