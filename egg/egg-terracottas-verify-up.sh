#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

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

exec 3<> $TERRACOTTASFILE; while read interracottas <&3; do {
	if [ $(echo "$interracottas" | cut -c1) != "#" ]; then
	
		TERRACOTTAID=$(echo "$interracottas" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$interracottas" | cut -d ":" -f2)

		
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

					echo "CHECKING TERRACOTTA $INSTANCESIZE http://$HOST/"

					#Terracotta Existence Check
					./log.sh "Start Terracotta$TERRACOTTAID Installation Check"
					check=`ssh $HOST "[ -d /home/ec2-user/terracotta-3.4.0_1/ ] && echo 1"`
					if [ "$check" != 1 ]; then
						./log-status-red.sh "Terracotta$TERRACOTTAID installation folder not found, will create"
						./egg-terracotta-create.sh $HOST
						./egg-terracotta-configure.sh $HOST
					else 
						./log.sh "Terracotta$TERRACOTTAID installation folder found"
					fi
					
					#Terracotta Status Check
					./log.sh "Start Terracotta$TERRACOTTAID Status Check"
                    processcheck=`ssh $HOST "export JAVA_HOME=/usr/lib/jvm/jre; /home/ec2-user/terracotta-3.4.0_1/platform/bin/server-stat.sh"`
                    ./log.sh "processcheck=$processcheck"
                    if `echo ${processcheck} | grep "localhost.health: OK" 1>/dev/null 2>&1`
                    then
                        ./log.sh "Terracotta$TERRACOTTAID health appears OK"
                    else
                        ./log-status-red.sh "Terracotta$TERRACOTTAID health appears FAIL"
                        ./egg-terracotta-stop.sh $HOST
                        ./egg-terracotta-start.sh $HOST $TERRACOTTAID
                    fi

				fi
			fi
		}; done; exec 4>&-
		
	
	fi
}; done; exec 3>&-
