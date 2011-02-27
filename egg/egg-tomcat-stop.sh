#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APPDIR=$2

#Check for Existing Lock
TOMCATSTOPLOCKTIMEOUTSECONDS=120
source egg-tomcat-stop-lock.sh


if [ "$ISTOMCATSTOPLOCK" == "0"  ]; then
    #Do the stop
    ./log-status.sh "Stopping Tomcat $APPDIR"
    #ssh -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"
    uselessjibberishvar=`</dev/null ssh -n -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"`
    #ssh -t -t $HOST "cd egg/$APPDIR/tomcat/bin/; chmod 777 *.sh;"
    uselessjibberishvar=`</dev/null ssh -n $HOST "cd egg/$APPDIR/tomcat/bin/; chmod 777 *.sh;"`
    ./log.sh "Calling $APPDIR Catalina shutdown.sh"
    uselessjibberishvar=`</dev/null ssh -n $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; export JRE_HOME=/usr/lib/jvm/jre; bash egg/$APPDIR/tomcat/bin/shutdown.sh"`
    ./log.sh "Waiting 5 seconds for $APPDIR Tomcat to shut down before sending hard pkill"
    sleep 5
    #Syntax of next line sensitive
    uselessjibberishvar=`</dev/null ssh -n $HOST "pkill -f egg/${APPDIR}/tomcat/conf; echo terminated"`
    #Syntax of above line sensitive
    ./log.sh "uselessjibberishvar=$uselessjibberishvar"
    ./log.sh "Waiting 40 seconds for $APPDIR Tomcat to fully shut down"
    sleep 40
fi


