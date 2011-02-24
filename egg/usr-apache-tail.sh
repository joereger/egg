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







echo "Tail Apache for which app? (Type the number and hit enter)"
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

#Read apps file
read APPNUM
if [ "$APPNUM" != "" ]; then
    COUNTDEUX=0
    while read inappsline;
    do
        #Ignore lines that start with a comment hash mark
        if [ $(echo "$inappsline" | cut -c1) != "#" ]; then
            APPNAME=$(echo "$inappsline" | cut -d ":" -f1)
            APACHEID=$(echo "$inappsline" | cut -d ":" -f2)
            COUNTDEUX=$(( $COUNTDEUX + 1 ))
            if [ "$COUNTDEUX" == "$APPNUM" ]; then
                #Read APACHESFILE
                LOGICALINSTANCEID=0
                while read inapachesline;
                do
                    #Ignore lines that start with a comment hash mark
                    if [ $(echo "$inapachesline" | cut -c1) != "#" ]; then
                        APACHEID_A=$(echo "$inapachesline" | cut -d ":" -f1)
                        LOGICALINSTANCEID=$(echo "$inapachesline" | cut -d ":" -f2)
                        if [ "$APACHEID_A" == "$APACHEID" ]; then
                            #Read AMAZONIIDSFILE
                            AMAZONINSTANCEID=""
                            HOST=""
                            while read amazoniidsline;
                            do
                                #Ignore lines that start with a comment hash mark
                                if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                                    LOGICALINSTANCEID_B=$(echo "$amazoniidsline" | cut -d ":" -f1)
                                    if [ "$LOGICALINSTANCEID_B" == "$LOGICALINSTANCEID" ]; then
                                        AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                                        HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)


                                        #Now I finally have enough to tail
                                        ssh -t -t $HOST "sudo tail -f /var/log/httpd/logs/$APPNAME-access_log"



                                    fi
                                fi
                            done < "$AMAZONIIDSFILE"
                        fi
                    fi
                done < "$APACHESFILE"
            fi
        fi
    done < "$APPSFILE"


fi