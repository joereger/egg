#!/bin/bash

export DONTREDITSTDOUTTOLOGFILE=1
source common.sh



tput clear




ROWS=0
exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
    if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
        TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
        LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
        APPNAME=$(echo "$intomcatline" | cut -d ":" -f3)
        APPDIR=$APPNAME$TOMCATID

        ROWS=$(( $ROWS + 1 ))
        tput cup $ROWS 1
        tput el

        echo "$APPDIR"

    fi
}; done; exec 3>&-

exec 3<> $INSTANCESFILE; while read ininstancesline <&3; do {
    if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
        LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
		AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
		ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
		EBSVOLUME=$(echo "$ininstancesline" | cut -d ":" -f6)
		EBSDEVICENAME=$(echo "$ininstancesline" | cut -d ":" -f7)
		exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
			if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
				LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
				if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
					AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
					HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
				fi
			fi
		}; done; exec 4>&-

        ROWS=$(( $ROWS + 1 ))
        tput cup $ROWS 1
        tput el

        echo "Instance$LOGICALINSTANCEID $AMAZONINSTANCEID"

    fi
}; done; exec 3>&-

COUNT=0
export done="false"
while [ $done == "false" ]
do

    COUNT=$(( $COUNT + 1 ))



    ROWS=0
    exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
        if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
            TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
            LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
            APPNAME=$(echo "$intomcatline" | cut -d ":" -f3)
            APPDIR=$APPNAME$TOMCATID
            STATUS=""
            exec 4<> $PULSEFILE; while read pulseline <&4; do {
                if [ $(echo "$pulseline" | cut -c1) != "#" ]; then
                    KEY=$(echo "$pulseline" | cut -d ":" -f1)
                    VALUE=$(echo "$pulseline" | cut -d ":" -f2)
                    if [ "$KEY" == "$APPDIR" ]; then
                        STATUS=$VALUE
                    fi
                fi
            }; done; exec 4>&-

            ROWS=$(( $ROWS + 1 ))
            tput cup $ROWS 30
            echo "$STATUS"

        fi
    }; done; exec 3>&-


    exec 3<> $INSTANCESFILE; while read ininstancesline <&3; do {
    if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
        LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
		AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
		ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
		EBSVOLUME=$(echo "$ininstancesline" | cut -d ":" -f6)
		EBSDEVICENAME=$(echo "$ininstancesline" | cut -d ":" -f7)
		exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
			if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
				LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
				if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
					AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
					HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
				fi
			fi
		}; done; exec 4>&-
            STATUS=""
            exec 4<> $PULSEFILE; while read pulseline <&4; do {
                if [ $(echo "$pulseline" | cut -c1) != "#" ]; then
                    KEY=$(echo "$pulseline" | cut -d ":" -f1)
                    VALUE=$(echo "$pulseline" | cut -d ":" -f2)
                    if [ "$KEY" == "$AMAZONINSTANCEID" ]; then
                        STATUS=$VALUE
                    fi
                fi
            }; done; exec 4>&-

            ROWS=$(( $ROWS + 1 ))
            tput cup $ROWS 30
            echo "$STATUS"

        fi
    }; done; exec 3>&-





    sleep 3
done





