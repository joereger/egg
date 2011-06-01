#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: TOMCATID HOST APPDIR MEMMIN MEMMAX"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a TOMCATID"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$3" == "" ]; then echo "Must provide an APPDIR"; exit; fi

TOMCATID=$1
HOST=$2
APPDIR=$3



tomcatcheck=`ssh $HOST "[ -d ./egg/$APPDIR/tomcat/ ] && echo 1"`
if [ "$tomcatcheck" == 1 ]; then

    #./egg-tomcat-stop.sh $HOST $APPDIR

    ssh $HOST "rm -f egg/$APPDIR/tomcat/logs/*"
    #ssh $HOST "touch egg/$APPDIR/tomcat/logs/catalina.out"

    #./egg-tomcat-start.sh $TOMCATID $HOST $APPDIR $MEMMIN $MEMMAX

else
    ./log.sh "Tomcat ${APPDIR}/tomcat/ directory not found so no logs to flush"
fi





