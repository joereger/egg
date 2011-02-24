#!/bin/bash

export DONTREDITSTDOUTTOLOGFILE=1
source common.sh

TERRACOTTASFILE=conf/terracottas.conf
INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi

if [ ! -f "$TERRACOTTASFILE" ]; then
  echo "Sorry, $TERRACOTTASFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

echo "Tail which tomcat's log file? (Type the number and hit enter)"
while read interrline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$interrline" | cut -c1) != "#" ]; then
	    TERRACOTTAID=$(echo "$interrline" | cut -d ":" -f1)
	    LOGICALINSTANCEID=$(echo "$interrline" | cut -d ":" -f2)
        echo "$TERRACOTTAID - Terracotta$TERRACOTTAID - LogicalInstance $LOGICALINSTANCEID"
	fi
done < "$TERRACOTTASFILE"

read CHOSENTERRACOTTAID
if [ "$CHOSENTERRACOTTAID" != "" ]; then

    while read interrline;
    do
        #Ignore lines that start with a comment hash mark
        if [ $(echo "$interrline" | cut -c1) != "#" ]; then
            TERRACOTTAID=$(echo "$interrline" | cut -d ":" -f1)
            LOGICALINSTANCEID=$(echo "$interrline" | cut -d ":" -f2)
            if [ "$CHOSENTERRACOTTAID" == "$TERRACOTTAID" ]; then

                while read amazoniidsline;
                do
                    #Ignore lines that start with a comment hash mark
                    if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                        LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
                        if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
                            AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                            HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)

                            #Restart this terracotta
                            echo "Stopping terracotta"
                            ./egg-terracotta-stop.sh $HOST
                            echo "Sleeping 10 seconds before starting terracotta"
                            sleep 10
                            ./egg-terracotta-start.sh $HOST $TERRACOTTAID
                            echo "Terracotta$TERRACOTTAID restarted"

                        fi
                    fi
                done < "$AMAZONIIDSFILE"

            fi
        fi
    done < "$TERRACOTTASFILE"


fi