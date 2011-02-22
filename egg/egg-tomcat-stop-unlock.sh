#!/bin/bash

#This script should be source included into another

#source common.sh
#
#if [ "$#" == "0" ]; then echo "!USAGE: APPDIR"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide a APPDIR"; exit; fi
#
#APPDIR=$1

#Check for Existing Lock
TOMCATSTOPLOCKSFILE=data/tomcat.stop.locks
if [ ! -f "$TOMCATSTOPLOCKSFILE" ]; then
  ./log.sh "$TOMCATSTOPLOCKSFILE does not exist so creating it."
  cp data/tomcat.stop.locks.sample $TOMCATSTOPLOCKSFILE
fi

#Record new lock, Delete any current line with this
sed -i "
/^${APPDIR}:/ d\
" $TOMCATSTOPLOCKSFILE

