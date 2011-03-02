#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

APACHESFILE=conf/apaches.conf
INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi


if [ ! -f "$APACHESFILE" ]; then
  echo "Sorry, $APACHESFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi


ALLISWELL=1

#Read APACHESFILE
exec 3<> $APACHESFILE; while read inapacheline <&3; do {
	if [ $(echo "$inapacheline" | cut -c1) != "#" ]; then
	
		APACHEID=$(echo "$inapacheline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$inapacheline" | cut -d ":" -f2)

		
		#Read INSTANCESFILE    
		exec 4<> $INSTANCESFILE; while read ininstancesline <&4; do {
			if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
			
				LOGICALINSTANCEID_B=$(echo "$ininstancesline" | cut -d ":" -f1)
				SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
				INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
				AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
				ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
				
				if [ "$LOGICALINSTANCEID_B" == "$LOGICALINSTANCEID" ]; then
				
					#Read AMAZONIIDSFILE
					AMAZONINSTANCEID=""
					HOST=""
					exec 5<> $AMAZONIIDSFILE; while read amazoniidsline <&5; do {
						if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
							LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
							if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
								AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
								HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
							fi
						fi
					}; done; exec 5>&-


                    ssh -t -t $HOST "sudo rm -f /var/log/httpd/*"


				fi
			fi
		}; done; exec 4>&-
		
	
	fi
}; done; exec 3>&-

