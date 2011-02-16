#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APP APPDIR TOMCATID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APP"; exit; fi
if [ "$3" == "" ]; then echo "Must provide an APPDIR"; exit; fi
if [ "$4" == "" ]; then echo "Must provide an TOMCATID"; exit; fi


HOST=$1
APP=$2
APPDIR=$3
TOMCATID=$4


APACHEZIP="apache-tomcat-7.0.6.zip"
APACHEZIPLOCATION="resources"
APACHEDIRINSIDEZIP="apache-tomcat-7.0.6"

./egg-tomcat-stop.sh $HOST $APPDIR
rm -f data/$APP.tomcatid$TOMCATID.instance.props.remote
rm -f data/$APP.tomcatid$TOMCATID.instance.props.tmp
ssh -t -t $HOST "mkdir -p egg"
scp $APACHEZIPLOCATION/$APACHEZIP ec2-user@$HOST:$APACHEZIP
ssh -t -t $HOST "rm -rf egg/$APPDIR"
ssh -t -t $HOST "mkdir -p egg/$APPDIR"
ssh -t -t $HOST "unzip $APACHEZIP -d egg/$APPDIR"
ssh -t -t $HOST "sudo chmod -R 755 egg/$APPDIR"
ssh -t -t $HOST "mv egg/$APPDIR/$APACHEDIRINSIDEZIP/ egg/$APPDIR/tomcat/"
ssh -t -t $HOST "rm $APACHEZIP"
ssh -t -t $HOST "cp egg/$APPDIR/tomcat/conf/server.xml egg/$APPDIR/tomcat/conf/server.xml.original"
ssh -t -t $HOST "rm -rf egg/$APPDIR/tomcat/webapps/docs"
ssh -t -t $HOST "rm -rf egg/$APPDIR/tomcat/webapps/examples"
ssh -t -t $HOST "rm -rf egg/$APPDIR/tomcat/webapps/host-manager"
ssh -t -t $HOST "rm -rf egg/$APPDIR/tomcat/webapps/manager"




