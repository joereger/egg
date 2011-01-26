#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: LOGICALINSTANCEID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a LOGICALINSTANCEID"; exit; fi

LOGICALINSTANCEID=$1

INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=conf/amazoniids.conf

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp conf/amazoniids-sample.conf $AMAZONIIDSFILE
fi
		
#Read INSTANCESFILE   
while read ininstancesline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID_IN=$(echo "$ininstancesline" | cut -d ":" -f1)
		INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f2)
		AMIID=$(echo "$ininstancesline" | cut -d ":" -f3)
		ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f4)
		
		#If this is the instance that should be started
		if [ "$LOGICALINSTANCEID_IN" == "$LOGICALINSTANCEID" ]; then
		
			#Default AMIID
			if [ "$AMIID" == "" ]; then
				AMIID="ami-08728661"
			fi
			
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
			
			echo "   "
			echo Starting LOGICALINSTANCEID=$LOGICALINSTANCEID $INSTANCESIZE AMAZONINSTANCEID=$AMAZONINSTANCEID HOST=$HOST ELASTICIP=$ELASTICIP
			
			#Determine whether this instance is running
			thisinstanceisup=0
			export RUNNING="running"
			export status=`${EC2_HOME}/bin/ec2-describe-instances $AMAZONINSTANCEID | grep INSTANCE | cut -f6`
			if [ "$status" == "$RUNNING" ]; then
				export thisinstanceisup=1  	
			fi
			echo Thisinstanceisup=$thisinstanceisup
			
			#Start an instance if necessary
			if [ ${thisinstanceisup} == "0" ]; then
				echo Will start amazon ec2 instance for logical instance $LOGICALINSTANCEID
				
				#TEMP BLOCK OUT
				#if [ "1" == "0" ]; then
				
					#Start command
					${EC2_HOME}/bin/ec2-start-instances $AMAZONINSTANCEID
		
					# Loop until the status changes to .running.
					sleep 30
					echo Starting instance ${AMAZONINSTANCEID}
					export RUNNING="running"
					export done="false"
					while [ $done == "false" ]
					do
					   export status=`${EC2_HOME}/bin/ec2-describe-instances ${AMAZONINSTANCEID} | grep INSTANCE | cut -f6`
					   if [ $status == ${RUNNING} ]; then
						  export done="true"
					   else
						  echo Waiting...
						  sleep 10
					   fi
					done
					echo Instance ${AMAZONINSTANCEID} is running
					
					
		
					# Associate the Elastic IP with the instance
					if [ "$ELASTICIP" != "" ]; then  
						echo Associating elastic IP address $ELASTICIP
						${EC2_HOME}/bin/ec2-associate-address $ELASTICIP -i ${AMAZONINSTANCEID}
						sleep 30
					fi
					
					#Get the IP address
					export ipaddress=`${EC2_HOME}/bin/ec2-describe-instances ${AMAZONINSTANCEID} | grep INSTANCE | cut -f18`
					echo IP Address of ${AMAZONINSTANCEID} is ${ipaddress}
				
					HOST=${ipaddress}
				
				#TEMP BLOCK OUT
				#fi
				
				#Delete any current line with this logicalinstanceid
				sed -i "
				/^${LOGICALINSTANCEID}:/ d\
				" $AMAZONIIDSFILE
				
				#Write a record to amazoniids.conf
				sed -i "
				/#BEGINDATA/ a\
				$LOGICALINSTANCEID:$AMAZONINSTANCEID:$HOST
				" $AMAZONIIDSFILE
				
			fi
		fi	
	fi
done < "$INSTANCESFILE"












