#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST MYSQLID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a MYSQLID"; exit; fi


HOST=$1
MYSQLID=$2

#Check for /conf/mysql/mysqlid$MYSQLID.my.cnf to see if I have unique settings for this one instance
MYCNFTMP=conf/mysql/default.my.cnf
if [ -e conf/mysql/mysqlid${MYSQLID}.my.cnf ]; then
	./log.sh "conf/mysql/mysqlid${MYSQLID}.my.cnf exists"
    MYCNFTMP=conf/mysql/mysqlid${MYSQLID}.my.cnf
else
	./log.sh "conf/mysql/mysqlid${MYSQLID}.my.cnf not found, using default my.cnf"
fi

#Copy to data
MYCNFLOCAL=data/mysqlid${MYSQLID}.my.cnf.local
MYCNFREMOTE=data/mysqlid${MYSQLID}.my.cnf.remote
cp $MYCNFTMP $MYCNFLOCAL


#Download the latest remote file
rm -f $MYCNFREMOTE
scp ec2-user@$HOST:/etc/my.cnf $MYCNFREMOTE


#Determine whether this new config is different than the latest
if  diff $MYCNFLOCAL $MYCNFREMOTE >/dev/null ; then
    ./log.sh "mysql$MYSQLID my.cnf remote is SAME as local"
    ./pulse-update.sh "MySQL$MYSQLID" "MY.CNF REMOTE SAME AS LOCAL"
else
    ./log.sh "mysql$MYSQLID my.cnf remote is DIFFERENT than local"
    ./pulse-update.sh "MySQL$MYSQLID" "MY.CNF REMOTE DIFFERENT THAN LOCAL"

    #Copy latest to the remote Apache host
    scp $MYCNFLOCAL ec2-user@$HOST:my.cnf
    ssh -t -t $HOST "sudo cp my.cnf /etc/my.cnf"
    ssh -t -t $HOST "sudo rm my.cnf"
    ssh -t -t $HOST "sudo /sbin/chkconfig mysqld on"

    #Make sure we have the latest locally
    scp ec2-user@$HOST:/etc/my.cnf $MYCNFREMOTE

    #Bounce MySQL
    ./pulse-update.sh "MySQL$MYSQLID" "BOUNCING MYSQL, STOPPING"
    ./egg-mysql-stop.sh $HOST
    ./pulse-update.sh "MySQL$MYSQLID" "BOUNCING MYSQL, STARTING"
    ./egg-mysql-start.sh $HOST
    ./pulse-update.sh "MySQL$MYSQLID" "DONE BOUNCING MYSQL"
fi



#scp $MYCNFLOCAL ec2-user@$HOST:my.cnf
#ssh -t -t $HOST "sudo cp my.cnf /etc/my.cnf"
#ssh -t -t $HOST "sudo rm my.cnf"
#ssh -t -t $HOST "sudo /sbin/chkconfig mysqld on"







