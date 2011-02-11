#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: LOGICALINSTANCEID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a LOGICALINSTANCEID"; exit; fi

LOGICALINSTANCEID=$1

INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi
		
#Read INSTANCESFILE   
while read ininstancesline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID_IN=$(echo "$ininstancesline" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
		AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
		ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
		
		#If this is the instance that should be started
		if [ "$LOGICALINSTANCEID_IN" == "$LOGICALINSTANCEID" ]; then
		
			#Default AMIID
			if [ "$AMIID" == "" ]; then
				AMIID="ami-08728661"
			fi
			
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
			
			echo "   "
			echo Stopping LOGICALINSTANCEID=$LOGICALINSTANCEID $INSTANCESIZE AMAZONINSTANCEID=$AMAZONINSTANCEID HOST=$HOST ELASTICIP=$ELASTICIP
			
			#Determine whether this instance is running
			thisinstanceisup=0
			export RUNNING="running"
			export status=`${EC2_HOME}/bin/ec2-describe-instances $AMAZONINSTANCEID | grep INSTANCE | cut -f6`
			if [ "$status" == "$RUNNING" ]; then
				export thisinstanceisup=1  	
			fi
			echo Thisinstanceisup=$thisinstanceisup
			
			#Start an instance if necessary
			if [ ${thisinstanceisup} == "1" ]; then
				echo Will stop amazon ec2 instance for logical instance $LOGICALINSTANCEID
				
				#TEMP BLOCK OUT
				#if [ "1" == "0" ]; then
				
					#Stop command
					${EC2_HOME}/bin/ec2-stop-instances $AMAZONINSTANCEID
		
					# Loop until the status changes to .running.
					sleep 30
					echo Starting instance ${AMAZONINSTANCEID}
					export STOPPED="stopped"
					export done="false"
					while [ $done == "false" ]
					do
					   export status=`${EC2_HOME}/bin/ec2-describe-instances ${AMAZONINSTANCEID} | grep INSTANCE | cut -f6`
					   if [ $status == ${STOPPED} ]; then
						  export done="true"
					   else
						  echo Waiting...
						  sleep 10
					   fi
					done
					echo Instance ${AMAZONINSTANCEID} is stopped
					
				
				#TEMP BLOCK OUT
				#fi
			
				
			fi
		fi	
	fi
done < "$INSTANCESFILE"












