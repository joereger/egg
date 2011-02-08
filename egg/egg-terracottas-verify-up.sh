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
  cp data/amazoniids-sample.conf $AMAZONIIDSFILE
fi


if [ ! -f "$TERRACOTTASFILE" ]; then
  echo "Sorry, $TERRACOTTASFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

#Read APACHESFILE
while read interraline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$interraline" | cut -c1) != "#" ]; then
	
		TERRACOTTAID=$(echo "$interraline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$interraline" | cut -d ":" -f2)

		
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

					echo CHECKING TERRACOTTA $INSTANCESIZE http://$HOST/

					#Terracotta Existence Check
					echo Start Terracotta Installation Check
					check=`ssh $HOST "[ -d /home/ec2-user/terracotta-3.4.0_1/ ] && echo 1"`
					if [ "$check" != 1 ]; then
						echo Terracotta installation folder not found, will create
						./egg-terracotta-create.sh $HOST
						./egg-terracotta-configure.sh $HOST
					else 
						echo Terracotta installation folder found
					fi
					
					#Terracotta Status Check
					echo Start Terracotta Status Check
                    processcheck=`ssh $HOST "export JAVA_HOME=/usr/lib/jvm/jre; /home/ec2-user/terracotta-3.4.0_1/platform/bin/server-stat.sh"`
                    echo processcheck=$processcheck
                    if `echo ${processcheck} | grep "localhost.health: OK" 1>/dev/null 2>&1`
                    then
                        echo "Terracotta health appears OK"
                    else
                        echo "Terracotta health appears FAIL"
                        ./egg-terracotta-stop.sh $HOST
                        ./egg-terracotta-start.sh $HOST
                    fi

				fi
			fi
		done < "$INSTANCESFILE"
		
	
	fi
done < "$TERRACOTTASFILE"
