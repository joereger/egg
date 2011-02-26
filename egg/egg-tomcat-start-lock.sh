#!/bin/bash

#This script should be source included into another

#source common.sh
#
#if [ "$#" == "0" ]; then echo "!USAGE: APPDIR TOMCATSTARTLOCKTIMEOUTSECONDS"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APPDIR"; exit; fi
#
#APPDIR=$1
#TOMCATSTARTLOCKTIMEOUTSECONDS=$2

if [ "$TOMCATSTARTLOCKTIMEOUTSECONDS" == "" ]; then
    TOMCATSTARTLOCKTIMEOUTSECONDS="120"
fi

#Check for Existing Lock
ISTOMCATSTARTLOCK=0
TOMCATSTARTLOCKSFILE=data/tomcat.start.locks
if [ ! -f "$TOMCATSTARTLOCKSFILE" ]; then
  ./log.sh "$TOMCATSTARTLOCKSFILE does not exist so creating it."
  cp data/tomcat.start.locks.sample $TOMCATSTARTLOCKSFILE
fi
while read tcstartline;
do
    #Ignore lines that start with a comment hash mark
    if [ $(echo "$tcstartline" | cut -c1) != "#" ]; then
        APPDIR_LOCK=$(echo "$tcstartline" | cut -d ":" -f1)
        LASTRUN=$(echo "$tcstartline" | cut -d ":" -f2)
        if [ "$APPDIR_LOCK" == "$APPDIR" ]; then
            ./log.sh "Tomcat Start Lock exists for $APPDIR"
            CURRENTTIME=`date +%s`
            LASTRUNPLUSTIMEOUT=$((LASTRUN+TOMCATSTARTLOCKTIMEOUTSECONDS))
            if [ "${CURRENTTIME}" -lt "${LASTRUNPLUSTIMEOUT}"  ]; then
                ./log.sh "Not starting, Tomcat Start Lock for $APPDIR exists"
                ISTOMCATSTOPLOCK=1
            else
                ./log.sh "Running start, Tomcat Start Lock for $APPDIR has expired"
            fi
        fi
    fi
done < "$TOMCATSTARTLOCKSFILE"


if [ "$ISTOMCATSTARTLOCK" == "0"  ]; then
    #First unlock it
    ./egg-tomcat-start-unlock.sh $APPDIR
    #Write a lock record
    CURRENTTIME=`date +%s`
    sed -i "
    /#BEGINDATA/ a\
    $APPDIR:$CURRENTTIME
    " $TOMCATSTARTLOCKSFILE
fi


