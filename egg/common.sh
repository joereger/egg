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
echo -e ${cc_black_cyan}`TZ=EST date +"%b%d"`" "`TZ=EST date +"%r"`" "$WHATTOLOG${c_reset} >> $LOGFILEINFO
#./log-status-green.sh "$0 $@"
#echo -e ${c_reset}

#Set up EC2 vars
export EC2_HOME=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=/home/ec2-user/.ec2/pk-***REMOVED***.pem
export EC2_CERT=/home/ec2-user/.ec2/cert-***REMOVED***.pem
export PATH=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/jre

#EC2 Name Tag for all instances
export EC2NAMETAG="eggpuppet"





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

APACHESFILE=conf/apaches.conf
if [ ! -f "$APACHESFILE" ]; then
  echo "Sorry, $APACHESFILE does not exist."
  exit 1
fi

INSTANCESFILE=conf/instances.conf
if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

TOMCATSFILE=conf/tomcats.conf
if [ ! -f "$TOMCATSFILE" ]; then
  echo "Sorry, $TOMCATSFILE does not exist."
  exit 1
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

URLSFILE=conf/urls.conf
if [ ! -f "$URLSFILE" ]; then
  echo "Sorry, $URLSFILE does not exist."
  exit 1
fi

APPSFILE=conf/apps.conf
if [ ! -f "$APPSFILE" ]; then
  echo "Sorry, $APPSFILE does not exist."
  exit 1
fi

MYSQLSFILE=conf/mysqls.conf
if [ ! -f "$MYSQLSFILE" ]; then
  echo "Sorry, $MYSQLSFILE does not exist."
  exit 1
fi

TERRACOTTASFILE=conf/terracottas.conf
if [ ! -f "$TERRACOTTASFILE" ]; then
  echo "Sorry, $TERRACOTTASFILE does not exist."
  exit 1
fi

