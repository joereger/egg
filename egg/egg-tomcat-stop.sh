#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APPDIR=$2

./log-status.sh "$APPDIR Stopping Tomcat"
ssh -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"
ssh -t -t $HOST "cd egg/$APPDIR/tomcat/bin/; chmod 777 *.sh;"
#ssh -t -t $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; bash egg/$APPDIR/tomcat/bin/catalina.sh stop"
./log.sh "Calling $APPDIR Catalina shutdown.sh"
uselessjibberishvar=`ssh $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; export JRE_HOME=/usr/lib/jvm/jre; bash egg/$APPDIR/tomcat/bin/shutdown.sh"`
./log.sh "Waiting 5 seconds for $APPDIR Tomcat to shut down before sending hard pkill"
sleep 5
ssh -t -t $HOST "pkill -f egg/${APPDIR}/tomcat/conf"

#ssh $HOST "ps -ef | grep $APPDIR | grep java | cut -d ' ' -f2"


