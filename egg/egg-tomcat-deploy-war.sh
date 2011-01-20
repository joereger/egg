#!/bin/bash

if [ "$#" == "0" ]; then echo "!USAGE: HOST APP APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APP"; exit; fi
if [ "$3" == "" ]; then echo "Must provide an APPDIR"; exit; fi

./common.sh

HOST=$1
APP=$2
APPDIR=$3


#Stop instance if it's running (it prolly is)
./egg-tomcat-stop.sh $HOST $APPDIR

#Delete ROOT dir, recreate it
ssh $HOST "rm -rf egg/$APPDIR/tomcat/webapps/ROOT"
ssh $HOST "mkdir egg/$APPDIR/tomcat/webapps/ROOT"

#Copy the WAR file
scp egg/conf/$APP/war/ROOT.war ec2-user@$HOST:ROOT.war

#Unzip the WAR file
ssh $HOST "unzip ROOT.war egg/$APPDIR/tomcat/webapps/ROOT"
