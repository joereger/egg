#!/bin/bash

source common.sh

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

echo "Tail which tomcat's log file? (Type the number and hit enter)"
while read intomcatline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
	    TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
	    LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
		APPNAME=$(echo "$intomcatline" | cut -d ":" -f3)
        echo "$TOMCATID - $APPNAME - LogicalInstance $LOGICALINSTANCEID"
	fi
done < "$TOMCATSFILE"

read CHOSENTOMCATID
if [ "$CHOSENTOMCATID" != "" ]; then

    while read intomcatline;
    do
        #Ignore lines that start with a comment hash mark
        if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
            TOMCATID_B=$(echo "$intomcatline" | cut -d ":" -f1)
            LOGICALINSTANCEID_B=$(echo "$intomcatline" | cut -d ":" -f2)
            APPNAME_B=$(echo "$intomcatline" | cut -d ":" -f3)
            if [ "$CHOSENTOMCATID" == "$TOMCATID_B" ]; then

                while read amazoniidsline;
                do
                    #Ignore lines that start with a comment hash mark
                    if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                        LOGICALINSTANCEID_C=$(echo "$amazoniidsline" | cut -d ":" -f1)
                        if [ "$LOGICALINSTANCEID_C" == "$LOGICALINSTANCEID_B" ]; then
                            AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                            HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)

                            APPDIR=$APPNAME_B$CHOSENTOMCATID
                            ssh -t -t $HOST "tail -f egg/${APPDIR}/tomcat/logs/catalina.out"


                        fi
                    fi
                done < "$AMAZONIIDSFILE"



            fi
        fi
    done < "$TOMCATSFILE"


fi