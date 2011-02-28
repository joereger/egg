#!/bin/bash

#This script should be source included into another

#source common.sh
#
#if [ "$#" == "0" ]; then echo "!USAGE: APPDIR TOMCATSTOPLOCKTIMEOUTSECONDS"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APPDIR"; exit; fi
#
#APPDIR=$1
#TOMCATSTOPLOCKTIMEOUTSECONDS=$2

if [ "$TOMCATSTOPLOCKTIMEOUTSECONDS" == "" ]; then
    TOMCATSTOPLOCKTIMEOUTSECONDS="120"
fi

#Check for Existing Lock
ISTOMCATSTOPLOCK=0
TOMCATSTOPLOCKSFILE=data/tomcat.stop.locks
if [ ! -f "$TOMCATSTOPLOCKSFILE" ]; then
  ./log.sh "$TOMCATSTOPLOCKSFILE does not exist so creating it."
  cp data/tomcat.stop.locks.sample $TOMCATSTOPLOCKSFILE
fi
exec 3<> $TOMCATSTOPLOCKSFILE; while read tcstopline <&3; do {
    if [ $(echo "$tcstopline" | cut -c1) != "#" ]; then
        APPDIR_LOCK=$(echo "$tcstopline" | cut -d ":" -f1)
        LASTRUN=$(echo "$tcstopline" | cut -d ":" -f2)
        if [ "$APPDIR_LOCK" == "$APPDIR" ]; then
            ./log.sh "Tomcat Stop Lock exists for $APPDIR"
            CURRENTTIME=`date +%s`
            LASTRUNPLUSTIMEOUT=$((LASTRUN+TOMCATSTOPLOCKTIMEOUTSECONDS))
            if [ "${CURRENTTIME}" -lt "${LASTRUNPLUSTIMEOUT}"  ]; then
                ./log.sh "Not stopping, Tomcat Stop Lock for $APPDIR exists"
                ISTOMCATSTOPLOCK=1
            else
                ./log.sh "Running stop, Tomcat Stop Lock for $APPDIR has expired"
            fi
        fi
    fi
}; done; exec 3>&-


if [ "$ISTOMCATSTOPLOCK" == "0"  ]; then
    #First unlock it
    ./egg-tomcat-stop-unlock.sh $APPDIR
    #Write a lock record
    CURRENTTIME=`date +%s`
    sed -i "
    /#BEGINDATA/ a\
    $APPDIR:$CURRENTTIME
    " $TOMCATSTOPLOCKSFILE
fi


