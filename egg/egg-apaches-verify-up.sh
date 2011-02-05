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
  cp data/amazoniids-sample.conf $AMAZONIIDSFILE
fi


if [ ! -f "$APACHESFILE" ]; then
  echo "Sorry, $APACHESFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

#Read APACHESFILE
while read inapachesline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$inapachesline" | cut -c1) != "#" ]; then
	
		APACHEID=$(echo "$inapachesline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$inapachesline" | cut -d ":" -f2)

		
		#Read INSTANCESFILE    
		while read ininstancesline;
		do
			#Ignore lines that start with a comment hash mark
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

					echo CHECKING APACHE $INSTANCESIZE http://$HOST/

					#Apache Existence Check
					echo Start Apache Check
					apachecheck=`ssh $HOST "[ -d /etc/httpd/conf/ ] && echo 1"`
					if [ "$apachecheck" != 1 ]; then
						echo Apache installation folder not found, will create
						./egg-apache-stop.sh $HOST
						./egg-apache-create.sh $HOST
						./egg-apache-configure.sh $APACHEID
						./egg-apache-start.sh $HOST
					else 
						echo Apache installation folder found
					fi
					
					#Apache Process Check
                    #This line very finickey...
                    processcheck=`ssh $HOST "[ -n \"\\\`pgrep httpd\\\`\" ] && echo 1"`
                    echo processcheck=$processcheck
					if [ "$processcheck" != 1 ]; then
						echo Apache process not found
						./egg-apache-stop.sh $HOST
						./egg-apache-configure.sh $APACHEID
						./egg-apache-start.sh $HOST
					else
						echo Apache process found
					fi



				fi
			fi
		done < "$INSTANCESFILE"
		
	
	fi
done < "$APACHESFILE"
