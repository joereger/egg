#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

APP=$1

TOMCATSFILE=conf/tomcats.conf
INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi


if [ ! -f "$TOMCATSFILE" ]; then
  echo "Sorry, $TOMCATSFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi



./log-status-green.sh "Deploy: Stopping all tomcats for $APP"
./egg-app-stop.sh $APP


./log-status-green.sh "Deploy: Sending WAR to all tomcats for $APP"
#Read TOMCATSFILE
while read intomcatline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then

		TOMCATID_A=$(echo "$intomcatline" | cut -d ":" -f1)
		LOGICALINSTANCEID_A=$(echo "$intomcatline" | cut -d ":" -f2)
		APPNAME_A=$(echo "$intomcatline" | cut -d ":" -f3)
		MEMMIN_A=$(echo "$intomcatline" | cut -d ":" -f4)
		MEMMAX_A=$(echo "$intomcatline" | cut -d ":" -f5)
		HTTPPORT_A=$((8100+$TOMCATID_A))

		if [ "$APPNAME_A" == "$APP" ]; then

			echo --FOUND $APP TOMCAT INSTANCE--
			echo TOMCATID=$TOMCATID_A
			echo LOGICALINSTANCEID=$LOGICALINSTANCEID_A
			echo APPNAME=$APPNAME_A
			echo MEMMIN=$MEMMIN_A
			echo MEMMAX=$MEMMAX_A
			echo HTTPPORT=$HTTPPORT_A

			#Determine APPDIR
			APPDIR=$APPNAME_A$TOMCATID_A
			echo APPDIR=$APPDIR


			#Read AMAZONIIDSFILE
            AMAZONINSTANCEID=""
            HOST=""
            while read amazoniidsline;
            do
                #Ignore lines that start with a comment hash mark
                if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                    LOGICALINSTANCEID_C=$(echo "$amazoniidsline" | cut -d ":" -f1)
                    if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID_C" ]; then
                        AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                        HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
                        echo "Found hostname for LOGICALINSTANCEID=$LOGICALINSTANCEID_A"
                    fi
                fi
            done < "$AMAZONIIDSFILE"

			#Deploy the WAR
			if [ "$HOST" != "" ]; then
				./egg-tomcat-deploy-war.sh $HOST $APP $APPDIR
			fi

		fi
	fi
done < "$TOMCATSFILE"

./log-status-green.sh "Deploy: Starting all tomcats for $APP"
./egg-app-start.sh $APP







