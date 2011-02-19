#!/bin/bash

source common.sh

INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf
TOMCATSFILE=conf/tomcats.conf
MYSQLSFILE=conf/mysqls.conf
TERRACOTTASFILE=conf/terracottas.conf
APACHESFILE=conf/apaches.conf

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi



echo "Terminate which Amazon instance? (Type the number and hit enter)"


#Read INSTANCESFILE
while read ininstancesline;
do
    #Ignore lines that start with a comment hash mark
    if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
        LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
        SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
        INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
        AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
        ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)

        #Read AMAZONIIDSFILE
        AMAZONINSTANCEID=""
        HOST=""
        while read amazoniidsline;
        do
            #Ignore lines that start with a comment hash mark
            if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
                if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
                    AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                    HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
                fi
            fi
        done < "$AMAZONIIDSFILE"

        #Read TOMCATSFILE
        TCECHO=""
        while read intomcatline;
        do
            #Ignore lines that start with a comment hash mark
            if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
                TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
                LOGICALINSTANCEID_C=$(echo "$intomcatline" | cut -d ":" -f2)
                if [ "$LOGICALINSTANCEID_C" == "$LOGICALINSTANCEID" ]; then
                    APP=$(echo "$intomcatline" | cut -d ":" -f3)
                    APPDIR=$APP$TOMCATID
                    TCECHO=$TCECHO" "$APPDIR
                fi
            fi
        done < "$TOMCATSFILE"

        #Read Mysqls
        MYSQLECHO=""
        while read inmysqlsline;
        do
            #Ignore lines that start with a comment hash mark
            if [ $(echo "$inmysqlsline" | cut -c1) != "#" ]; then
                MYSQLID=$(echo "$inmysqlsline" | cut -d ":" -f1)
                LOGICALINSTANCEID_D=$(echo "$inmysqlsline" | cut -d ":" -f2)
                if [ "$LOGICALINSTANCEID_D" == "$LOGICALINSTANCEID" ]; then
                    MYSQLECHO=$MYSQLECHO" mysql"$MYSQLID
                fi
            fi
        done < "$MYSQLSFILE"

        #Read Terracottas
        TERECHO=""
        while read inmterrline;
        do
            #Ignore lines that start with a comment hash mark
            if [ $(echo "$inmterrline" | cut -c1) != "#" ]; then
                TERRACOTTAID=$(echo "$inmterrline" | cut -d ":" -f1)
		        LOGICALINSTANCEID_E=$(echo "$inmterrline" | cut -d ":" -f2)
                if [ "$LOGICALINSTANCEID_E" == "$LOGICALINSTANCEID" ]; then
                    TERECHO=$TERECHO" terracotta"$TERRACOTTAID
                fi
            fi
        done < "$TERRACOTTASFILE"

        #Read Apaches
        APAACHEECHO=""
        while read inapacheline;
        do
            #Ignore lines that start with a comment hash mark
            if [ $(echo "$inapacheline" | cut -c1) != "#" ]; then
                APACHEID=$(echo "$inapacheline" | cut -d ":" -f1)
		        LOGICALINSTANCEID_F=$(echo "$inapacheline" | cut -d ":" -f2)
                if [ "$LOGICALINSTANCEID_F" == "$LOGICALINSTANCEID" ]; then
                    APAACHEECHO=$APAACHEECHO" apache"$APACHEID
                fi
            fi
        done < "$APACHESFILE"


        echo "$LOGICALINSTANCEID - $INSTANCESIZE $AMAZONINSTANCEID - $TCECHO$TERECHO$APAACHEECHO$MYSQLECHO"

    fi
done < "$INSTANCESFILE"



read LOGICALINSTANCEIDTOKILL
if [ "$LOGICALINSTANCEIDTOKILL" != "" ]; then
    ./egg-instance-terminate.sh $LOGICALINSTANCEIDTOKILL
fi


























