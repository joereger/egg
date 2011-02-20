#!/bin/bash

source common.sh

APPSFILE=conf/apps.conf

if [ ! -f "$APPSFILE" ]; then
  echo "Sorry, $APPSFILE does not exist."
  exit 1
fi

echo "Deploy war to which app? (Type the number and hit enter)"
COUNT=0
while read inappsline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$inappsline" | cut -c1) != "#" ]; then
		APPNAME=$(echo "$inappsline" | cut -d ":" -f1)
		COUNT=$(( $COUNT + 1 ))
        echo "$COUNT - $APPNAME"
	fi
done < "$APPSFILE"

read APP
if [ "$APP" != "" ]; then
    CHOSENAPP=""
    COUNTDEUX=0
    while read inappsline;
    do
        #Ignore lines that start with a comment hash mark
        if [ $(echo "$inappsline" | cut -c1) != "#" ]; then
            APPNAME=$(echo "$inappsline" | cut -d ":" -f1)
            COUNTDEUX=$(( $COUNTDEUX + 1 ))
            if [ "$COUNTDEUX" == "$APP" ]; then
                CHOSENAPP=$APPNAME
            fi
        fi
    done < "$APPSFILE"

    if [ "$CHOSENAPP" != "" ]; then
        #echo "$CHOSENAPP will be stopped"
        ./log-status-green.sh "$CHOSENAPP will have wars deployed"
        ./egg-app-deploy-war.sh $CHOSENAPP
        ./egg-app-start.sh $CHOSENAPP
    fi
fi