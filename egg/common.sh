#!/bin/bash

source colors.sh
source loginclude.sh

#Redirect stdout to LOGFILEDEBUG
#$DONTREDITSTDOUTTOLOGFILE allows me to turn this off for certain scripts
if [ "$DONTREDITSTDOUTTOLOGFILE" == "" ]; then
    exec > >(tee -a $LOGFILEDEBUG)
    exec 2>&1
fi

#Log script execution yo yo yo
#echo -e ${cc_black_cyan}
WHATTOLOG="$0 $@"
echo -e ${cc_black_cyan}`TZ=EST date +"%b%d"`" "`TZ=EST date +"%r"`" "$WHATTOLOG${c_reset} >> $LOGFILEDEBUG
#echo -e ${cc_black_cyan}`TZ=EST date +"%b%d"`" "`TZ=EST date +"%r"`" "$WHATTOLOG${c_reset} >> $LOGFILEINFO
#./log-status-green.sh "$0 $@"
#echo -e ${c_reset}


#Figure out which /conf/ directory to use
CONFDIR="conf/default"
if [ -f "000-use-conf-socketware.conf" ]; then
    #echo "CONFDIR = conf/socketware"
    ./log-debug.sh "CONFDIR = conf/socketware"
    CONFDIR="conf/socketware"
else
    #echo "CONFDIR = conf/default"
    CONFDIR="conf/default"
fi


#This file sets ec2 vars,etc
source $CONFDIR/common.sh


APACHESFILE=$CONFDIR/apaches.conf
if [ ! -f "$APACHESFILE" ]; then
  echo "Sorry, $APACHESFILE does not exist."
  exit 1
fi

SNAPSHOTSFILE=$CONFDIR/snapshots.conf
if [ ! -f "$SNAPSHOTSFILE" ]; then
  echo "Sorry, $SNAPSHOTSFILE does not exist."
  exit 1
fi

INSTANCESFILE=$CONFDIR/instances.conf
if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

TOMCATSFILE=$CONFDIR/tomcats.conf
if [ ! -f "$TOMCATSFILE" ]; then
  echo "Sorry, $TOMCATSFILE does not exist."
  exit 1
fi

URLSFILE=$CONFDIR/urls.conf
if [ ! -f "$URLSFILE" ]; then
  echo "Sorry, $URLSFILE does not exist."
  exit 1
fi

APPSFILE=$CONFDIR/apps.conf
if [ ! -f "$APPSFILE" ]; then
  echo "Sorry, $APPSFILE does not exist."
  exit 1
fi

MYSQLSFILE=$CONFDIR/mysqls.conf
if [ ! -f "$MYSQLSFILE" ]; then
  echo "Sorry, $MYSQLSFILE does not exist."
  exit 1
fi

MONGODBSFILE=$CONFDIR/mongodbs.conf
if [ ! -f "$MONGODBSFILE" ]; then
  echo "Sorry, $MONGODBSFILE does not exist."
  exit 1
fi

TERRACOTTASFILE=$CONFDIR/terracottas.conf
if [ ! -f "$TERRACOTTASFILE" ]; then
  echo "Sorry, $TERRACOTTASFILE does not exist."
  exit 1
fi

PULSEFILE=data/pulse.updates
if [ ! -f "$PULSEFILE" ]; then
  echo "$PULSEFILE does not exist so creating it."
  cp data/pulse.updates.sample $PULSEFILE
fi

CRONLOCKSFILE=data/cron.locks
if [ ! -f "$CRONLOCKSFILE" ]; then
  echo "$CRONLOCKSFILE does not exist so creating it."
  echo "$CRONLOCKSFILE does not exist so creating it." >> $LOGFILEDEBUG
  cp data/cron.locks.sample $CRONLOCKSFILE
fi

AMAZONIIDSFILE=data/amazoniids.conf
if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi

CHECKTOMCATSFILE=data/check.tomcats
if [ ! -f "$CHECKTOMCATSFILE" ]; then
  echo "$CHECKTOMCATSFILE does not exist so creating it."
  cp $CHECKTOMCATSFILE.sample $CHECKTOMCATSFILE
fi

TOMCATSTOPLOCKSFILE=data/tomcat.stop.locks
if [ ! -f "$TOMCATSTOPLOCKSFILE" ]; then
  ./log.sh "$TOMCATSTOPLOCKSFILE does not exist so creating it."
  cp data/tomcat.stop.locks.sample $TOMCATSTOPLOCKSFILE
fi

#echo "reached bottom of egg/common.sh"