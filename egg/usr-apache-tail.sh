#!/bin/bash

source common.sh

APPSFILE=conf/apps.conf

if [ ! -f "$APPSFILE" ]; then
  echo "Sorry, $APPSFILE does not exist."
  exit 1
fi

APACHESFILE=conf/apaches.conf

if [ ! -f "$APACHESFILE" ]; then
  echo "Sorry, $APACHESFILE does not exist."
  exit 1
fi

AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi





#Read apps file
if [ "$1" == "" ]; then
    echo "Tail Apache for which app? (Type the number and hit enter)"
    COUNT=0
    exec 3<> $APPSFILE; while read inappsline <&3; do {
        if [ $(echo "$inappsline" | cut -c1) != "#" ]; then
            APPNAME=$(echo "$inappsline" | cut -d ":" -f1)
            COUNT=$(( $COUNT + 1 ))
            echo "$COUNT - $APPNAME"
        fi
    }; done; exec 3>&-
    read APACHENUM
else
    APACHENUM=$1
fi


if [ "$2" == "" ]; then
    echo "Which type of log? (Type the number and hit enter)"
    echo "1 - access log (default, hit enter)"
    echo "2 - referer log"
    echo "3 - user agent log"
    echo "4 - instance performance log"
    read LOGTYPE
else
    LOGTYPE=$2
fi

echo "APACHENUM=$APACHENUM LOGTYPE=$LOGTYPE"

if [ "$APACHENUM" != "" ]; then
    COUNTDEUX=0
    exec 3<> $APPSFILE; while read inappsline <&3; do {
        if [ $(echo "$inappsline" | cut -c1) != "#" ]; then
            APPNAME=$(echo "$inappsline" | cut -d ":" -f1)
            APACHEID=$(echo "$inappsline" | cut -d ":" -f2)
            COUNTDEUX=$(( $COUNTDEUX + 1 ))
            if [ "$COUNTDEUX" == "$APACHENUM" ]; then
                #Read APACHESFILE
                LOGICALINSTANCEID=0
                exec 4<> $APACHESFILE; while read inapacheline <&4; do {
                    if [ $(echo "$inapacheline" | cut -c1) != "#" ]; then
                        APACHEID_A=$(echo "$inapacheline" | cut -d ":" -f1)
                        LOGICALINSTANCEID=$(echo "$inapacheline" | cut -d ":" -f2)
                        if [ "$APACHEID_A" == "$APACHEID" ]; then
                            #Read AMAZONIIDSFILE
                            AMAZONINSTANCEID=""
                            HOST=""
                            exec 5<> $AMAZONIIDSFILE; while read amazoniidsline <&5; do {
                                if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                                    LOGICALINSTANCEID_B=$(echo "$amazoniidsline" | cut -d ":" -f1)
                                    if [ "$LOGICALINSTANCEID_B" == "$LOGICALINSTANCEID" ]; then
                                        AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                                        HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)

                                        if [ "$LOGTYPE" == "1" ]; then
                                            ssh -t -t $HOST "sudo tail -f --lines=100 /var/log/httpd/$APPNAME-access_log"
                                        elif [ "$LOGTYPE" == "2" ]; then
                                            ssh -t -t $HOST "sudo tail -f --lines=100 /var/log/httpd/$APPNAME-referer_log"
                                        elif [ "$LOGTYPE" == "3" ]; then
                                            ssh -t -t $HOST "sudo tail -f --lines=100 /var/log/httpd/$APPNAME-agent_log"
                                        elif [ "$LOGTYPE" == "4" ]; then
                                            ssh -t -t $HOST "sudo tail -f --lines=100 /var/log/httpd/$APPNAME-instanceperformance_log"
                                        else
                                            ssh -t -t $HOST "sudo tail -f --lines=100 /var/log/httpd/$APPNAME-access_log"
                                        fi



                                    fi
                                fi
                            }; done; exec 5>&-
                        fi
                    fi
                }; done; exec 4>&-
            fi
        fi
    }; done; exec 3>&-


fi