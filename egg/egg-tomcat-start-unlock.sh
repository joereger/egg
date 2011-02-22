#!/bin/bash

#This script should be source included into another

#source common.sh
#
#if [ "$#" == "0" ]; then echo "!USAGE: APPDIR"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide a APPDIR"; exit; fi
#
#APPDIR=$1

#Check for Existing Lock
TOMCATSTARTLOCKSFILE=data/tomcat.start.locks
if [ ! -f "$TOMCATSTARTLOCKSFILE" ]; then
  ./log.sh "$TOMCATSTARTLOCKSFILE does not exist so creating it."
  cp data/tomcat.stop.locks.sample $TOMCATSTARTLOCKSFILE
fi

#Record new lock, Delete any current line with this
sed -i "
/^${APPDIR}:/ d\
" $TOMCATSTARTLOCKSFILE

