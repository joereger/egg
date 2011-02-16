#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APP APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APP"; exit; fi
if [ "$3" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APP=$2
APPDIR=$3


#Stop tomcat if it's running (it prolly is)
./log-status.sh "Deploy: Stopping Tomcat $APPDIR"
./egg-tomcat-stop.sh $HOST $APPDIR

#Delete ROOT dir, recreate it
./log-status.sh "Deploy: Delete root dirs $APPDIR"
ssh -t -t $HOST "rm -rf egg/$APPDIR/tomcat/webapps/ROOT"
ssh -t -t $HOST "mkdir egg/$APPDIR/tomcat/webapps/ROOT"

#Copy the WAR file
./log-status.sh "Deploy: Copy WAR file $APPDIR"
scp war/$APP/ROOT.war ec2-user@$HOST:ROOT.war
ssh -t -t $HOST "cp ROOT.war egg/$APPDIR/ROOT.war"
ssh -t -t $HOST "rm -f ROOT.war"

#Unzip the WAR file
./log-status.sh "Deploy: Unzip WAR file $APPDIR"
ssh -t -t $HOST "unzip egg/$APPDIR/ROOT.war -d egg/$APPDIR/tomcat/webapps/ROOT"
ssh -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"
