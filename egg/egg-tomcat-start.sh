#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APPDIR MEMMIN MEMMAX"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APPDIR=$2
MEMMIN=$3
MEMMAX=$4


if [ "$MEMMIN" == "" ]; then
    MEMMIN="128"
fi

if [ "$MEMMAX" == "" ]; then
    MEMMAX="256"
fi

./log-status.sh "Starting Tomcat $APPDIR"
ssh -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"
ssh -t -t $HOST "cd egg/$APPDIR/tomcat/bin/; chmod 777 *.sh;"
#ssh -t -t $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; export JRE_HOME=$JAVA_HOME; bash egg/$APPDIR/tomcat/bin/catalina.sh start"
#ssh -t -t $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; export JRE_HOME=/usr/lib/jvm/jre; bash egg/$APPDIR/tomcat/bin/catalina.sh start"
./log.sh "Calling $APPDIR Catalina startup.sh"
ssh $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; export JRE_HOME=/usr/lib/jvm/jre; export CATALINA_OPTS=\"-server -Xms${MEMMIN}m -Xmx${MEMMAX}m\"; bash egg/$APPDIR/tomcat/bin/startup.sh"