#!/bin/bash

source common.sh

APPSFILE=conf/apps.conf

if [ ! -f "$APPSFILE" ]; then
  echo "Sorry, $APPSFILE does not exist."
  exit 1
fi

echo "Start which app? (Type the number and hit enter)"
COUNT=0
exec 3<> $APPSFILE; while read inappsline <&3; do {
	if [ $(echo "$inappsline" | cut -c1) != "#" ]; then
		APPNAME=$(echo "$inappsline" | cut -d ":" -f1)
		COUNT=$(( $COUNT + 1 ))
        echo "$COUNT - $APPNAME"
	fi
}; done; exec 3>&-

read APP
if [ "$APP" != "" ]; then
    CHOSENAPP=""
    COUNTDEUX=0
    exec 3<> $APPSFILE; while read inappsline <&3; do {
        if [ $(echo "$inappsline" | cut -c1) != "#" ]; then
            APPNAME=$(echo "$inappsline" | cut -d ":" -f1)
            COUNTDEUX=$(( $COUNTDEUX + 1 ))
            if [ "$COUNTDEUX" == "$APP" ]; then
                CHOSENAPP=$APPNAME
            fi
        fi
    }; done; exec 3>&-

    if [ "$CHOSENAPP" != "" ]; then
        #echo "$CHOSENAPP will be stopped"
        ./log-status-green.sh "$CHOSENAPP will be restarted to have its config updated"
        ./egg-app-stop.sh $CHOSENAPP
        ./log.sh "$CHOSENAPP sleeping 10 seconds before start"
        sleep 10
        ./egg-app-start.sh $CHOSENAPP
    fi
fi