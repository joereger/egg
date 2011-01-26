#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APPDIR=$2
APACHEZIP="apache-tomcat-7.0.6.zip"
APACHEZIPLOCATION="resources"
APACHEDIRINSIDEZIP="apache-tomcat-7.0.6"

./egg-tomcat-stop.sh $HOST $APPDIR
ssh $HOST "mkdir -p egg"
scp $APACHEZIPLOCATION/$APACHEZIP ec2-user@$HOST:$APACHEZIP
ssh $HOST "rm -rf egg/$APPDIR"
ssh $HOST "mkdir -p egg/$APPDIR"
ssh $HOST "unzip $APACHEZIP -d egg/$APPDIR"
ssh $HOST "mv egg/$APPDIR/$APACHEDIRINSIDEZIP/ egg/$APPDIR/tomcat/"
ssh $HOST "rm $APACHEZIP"
ssh $HOST "cp egg/$APPDIR/tomcat/conf/server.xml egg/$APPDIR/tomcat/conf/server.xml.original"




