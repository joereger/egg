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
ssh -t -t $HOST "mkdir -p egg"
scp $APACHEZIPLOCATION/$APACHEZIP ec2-user@$HOST:$APACHEZIP
ssh -t -t $HOST "rm -rf egg/$APPDIR"
ssh -t -t $HOST "mkdir -p egg/$APPDIR"
ssh -t -t $HOST "unzip $APACHEZIP -d egg/$APPDIR"
ssh -t -t $HOST "sudo chmod -R 755 egg/$APPDIR"
ssh -t -t $HOST "mv egg/$APPDIR/$APACHEDIRINSIDEZIP/ egg/$APPDIR/tomcat/"
ssh -t -t $HOST "rm $APACHEZIP"
ssh -t -t $HOST "cp egg/$APPDIR/tomcat/conf/server.xml egg/$APPDIR/tomcat/conf/server.xml.original"




