#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: LOGICALINSTANCEID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a LOGICALINSTANCEID"; exit; fi

LOGICALINSTANCEID=$1

		
#Read INSTANCESFILE   
exec 3<> $INSTANCESFILE; while read ininstancesline <&3; do {
	if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID_IN=$(echo "$ininstancesline" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
		AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
		ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
		
		#If this is the instance that should be started
		if [ "$LOGICALINSTANCEID_IN" == "$LOGICALINSTANCEID" ]; then

			
			#Read AMAZONIIDSFILE
			AMAZONINSTANCEID=""
		    HOST=""
			exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
				if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
					LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
					if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
						AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
						HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
					fi
				fi
			}; done; exec 4>&-
			

			DISKSPACEAVAILABLE=`ssh $HOST "df / | awk '{ print \\$4 }' | tail -n 1"`
            echo "DISKSPACEAVAILABLE=$DISKSPACEAVAILABLE"




		fi	
	fi
}; done; exec 3>&-












