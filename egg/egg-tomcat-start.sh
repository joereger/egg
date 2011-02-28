#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: TOMCATID HOST APPDIR MEMMIN MEMMAX"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a TOMCATID"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$3" == "" ]; then echo "Must provide an APPDIR"; exit; fi

TOMCATID=$1
HOST=$2
APPDIR=$3
MEMMIN=$4
MEMMAX=$5


if [ "$MEMMIN" == "" ]; then
    MEMMIN="128"
fi

if [ "$MEMMAX" == "" ]; then
    MEMMAX="256"
fi


#Check for Existing Lock
TOMCATSTARTLOCKTIMEOUTSECONDS=120
source egg-tomcat-start-lock.sh


if [ "$ISTOMCATSTARTLOCK" == "0"  ]; then
    #Do the start
    export RESTARTIFCONFIGHASCHANGED="NORESTART"
    ./egg-tomcat-configure.sh $TOMCATID $RESTARTIFCONFIGHASCHANGED
    ./log-status.sh "Starting Tomcat $APPDIR"
    #ssh -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"
    uselessjibberishvar=`ssh -n -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"`
    #ssh -t -t $HOST "cd egg/$APPDIR/tomcat/bin/; chmod 777 *.sh;"
    uselessjibberishvar=`ssh -n $HOST "cd egg/$APPDIR/tomcat/bin/; chmod 777 *.sh;"`
    ./log.sh "Calling $APPDIR Catalina startup.sh"
    #ssh $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; export JRE_HOME=/usr/lib/jvm/jre; export CATALINA_OPTS=\"-server -Xms${MEMMIN}m -Xmx${MEMMAX}m\"; bash egg/$APPDIR/tomcat/bin/startup.sh"
    uselessjibberishvar=`ssh -n $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; export JRE_HOME=/usr/lib/jvm/jre; export CATALINA_OPTS=\"-server -Xms${MEMMIN}m -Xmx${MEMMAX}m\"; bash egg/$APPDIR/tomcat/bin/startup.sh"`
    echo $uselessjibberishvar
fi

