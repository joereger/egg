#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: TIMEPERIOD"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a TIMEPERIOD"; exit; fi

TIMEPERIOD=$1

exec 3<> $SNAPSHOTSFILE; while read insnapshotsline <&3; do {
	if [ $(echo "$insnapshotsline" | cut -c1) != "#" ]; then

	    EBSVOLUME=$(echo "$insnapshotsline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$insnapshotsline" | cut -d ":" -f2)
		DESCRIPTION=$(echo "$insnapshotsline" | cut -d ":" -f3)


		HOST=""
		exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
			if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
				LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
				if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
					HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
				fi
			fi
		}; done; exec 4>&-


        if [ "$EBSVOLUME" != "" ]; then
            if [ "$HOST" == "" ]; then
                HOST="nohost"
            fi

            ./egg-snapshot.sh $EBSVOLUME $TIMEPERIOD $HOST "${DESCRIPTION}"

        fi

	fi
}; done; exec 3>&-


