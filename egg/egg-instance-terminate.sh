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
			echo Terminating LOGICALINSTANCEID=$LOGICALINSTANCEID $INSTANCESIZE AMAZONINSTANCEID=$AMAZONINSTANCEID HOST=$HOST ELASTICIP=$ELASTICIP
			
			#Determine whether this instance is running
			thisinstanceisup=0
			export RUNNING="running"
			export status=`${EC2_HOME}/bin/ec2-describe-instances $AMAZONINSTANCEID | grep INSTANCE | cut -f6`
			if [ "$status" == "$RUNNING" ]; then
				export thisinstanceisup=1  	
			fi
			echo Thisinstanceisup=$thisinstanceisup
			

			if [ ${thisinstanceisup} == "1" ]; then
				echo "Will stop amazon ec2 instance for logical instance $LOGICALINSTANCEID"

				#Try for some graceful shutdown of MySQL
				./egg-mysql-stop.sh $HOST

                #Terminate command
                ${EC2_HOME}/bin/ec2-terminate-instances $AMAZONINSTANCEID
			
				#Delete any current line with this logicalinstanceid
				sed -i "
				/^${LOGICALINSTANCEID}:/ d\
				" $AMAZONIIDSFILE
			fi
		fi	
	fi
done < "$INSTANCESFILE"


#Any time we change instances we have to update the apacheconfig
./egg-apaches-configure-all.sh $HOST

