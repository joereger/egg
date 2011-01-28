#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

APACHESFILE=conf/apaches.conf
INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=conf/amazoniids.conf

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp conf/amazoniids-sample.conf $AMAZONIIDSFILE
fi


if [ ! -f "$APACHESFILE" ];
then
  echo "Sorry, $APACHESFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ];
then
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
					while read amazoniidsline;
					do
						#Ignore lines that start with a comment hash mark
						if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
							LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
							if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
								AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f3)
								HOST=$(echo "$amazoniidsline" | cut -d ":" -f4)
							fi
						fi
					done < "$AMAZONIIDSFILE"
				
				
					echo "  "
					echo CHECKING APACHE $APPNAME $INSTANCESIZE http://$HOST:$HTTPPORT/
					
					#Instance Check
					echo Start Instance Check
					export thisinstanceisup=0
					export RUNNING="running"
					export status=`${EC2_HOME}/bin/ec2-describe-instances $AMAZONINSTANCEID | grep INSTANCE | cut -f6`
					if [ $status == ${RUNNING} ]; then
						echo Instance found
						export thisinstanceisup=1  	
					else 
						echo Instance not found, will create
						export thisinstanceisup=0 
						#Create the instance
						./egg-verify-instances-up.sh
						#Read AMAZONIIDSFILE... again now that a new instance has been spun up
						while read amazoniidsline;
						do
							#Ignore lines that start with a comment hash mark
							if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
								LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
								if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
									AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f3)
									HOST=$(echo "$amazoniidsline" | cut -d ":" -f4)
								fi
							fi
						done < "$AMAZONIIDSFILE"
					fi
					
					#Apache Check
					#TODO Check
					
					#HTTP Check
					echo Start HTTP Check
					url="http://$HOST:$HTTPPORT/"
					retries=1
					timeout=60
					status=`wget -t 1 -T 60 $url 2>&1 | egrep "HTTP" | awk {'print $6'}`
					if [ "$status" == "200" ]; then
						echo HTTP 200 found
					else
						echo HTTP 200 not found, will stop/start tomcat
						./egg-tomcat-stop.sh $HOST $APPDIR
						./egg-tomcat-start.sh $HOST $APPDIR
					fi
					
				fi
			fi
		done < "$INSTANCESFILE"
		
	
	fi
done < "$APACHESFILE"