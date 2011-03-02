#!/bin/bash

source common.sh

echo "Deploy war to which app? (Type the number and hit enter)"
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
        ./log-status-green.sh "$CHOSENAPP WARs deploy start"
        ./egg-app-deploy-war.sh $CHOSENAPP
        ./egg-app-start.sh $CHOSENAPP
        ./log-status-green.sh "$CHOSENAPP WARs deploy end"
    fi
fi