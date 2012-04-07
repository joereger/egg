#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

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

					#Apache Existence Check
					./log.sh "Start Apache$APACHEID Installation Check"
					apachecheck=`ssh $HOST "[ -d /etc/httpd/conf/ ] && echo 1"`
					if [ "$apachecheck" != 1 ]; then
					    ALLISWELL=0
					    ./pulse-update.sh "Apache$APACHEID" "NOT FOUND, WILL CREATE"
						./log-status-red.sh "Apache$APACHEID installation folder not found, will create"
						./egg-apache-stop.sh $HOST
						./egg-apache-create.sh $HOST
						./egg-apache-configure.sh $APACHEID
						./egg-apache-start.sh $HOST
						./pulse-update.sh "Apache$APACHEID" "DONE CREATING"
					else 
						./log.sh "Apache$APACHEID installation folder found"
					fi
					
					#Apache Process Check
					./log.sh "Start Apache$APACHEID Process Check"
                    #This line very finickey...
                    processcheck=`ssh $HOST "[ -n \"\\\`pgrep httpd\\\`\" ] && echo 1"`
                    ./log.sh "processcheck=$processcheck"
					if [ "$processcheck" != 1 ]; then
					    ALLISWELL=0
					    ./pulse-update.sh "Apache$APACHEID" "PROCESS NOT FOUND, RESTARTING"
					    ./mail.sh "Apache$APACHEID process not found, restarting" "donde esta apache?"
						./log-status-red.sh "Apache$APACHEID process not found"
						./egg-apache-stop.sh $HOST
						./egg-apache-configure.sh $APACHEID
						./egg-apache-start.sh $HOST
						./pulse-update.sh "Apache$APACHEID" "DONE RESTARTING"
					else
						./log.sh "Apache$APACHEID process found"
					fi

					#Check the configuration... will only adjust/bounce if something's changed
					./egg-apache-configure.sh $APACHEID

                    ./pulse-update.sh "Apache$APACHEID" "DONE RESTARTING AND RECONFIGURING"

				fi
			fi
		}; done; exec 4>&-
		
	
	fi
}; done; exec 3>&-

if [ "$ALLISWELL" == "1"  ]; then
    ./log-status.sh "Apaches AllIsWell `date`"
    ./pulse-update.sh "Apache$APACHEID" "OK"
fi
