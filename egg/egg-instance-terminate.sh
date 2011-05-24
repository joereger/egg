#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: LOGICALINSTANCEID FORCE(optional)"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a LOGICALINSTANCEID"; exit; fi

LOGICALINSTANCEID=$1
FORCE=$2
if [ $FORCE == "" ]; then FORCE="0"; exit; fi
		
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
		
			#Default AMIID
			if [ "$AMIID" == "" ]; then
				AMIID="ami-08728661"
			fi
			
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

				#Try for some graceful shutdown
				./egg-instance-stop.sh $LOGICALINSTANCEID

                #Terminate command
                ${EC2_HOME}/bin/ec2-terminate-instances $AMAZONINSTANCEID
			
				#Delete any current line with this logicalinstanceid
				sed -i "
				/^${LOGICALINSTANCEID}:/ d\
				" $AMAZONIIDSFILE

			else
			    #If force (usually from egg-instances-verify-up.sh just before creation) then do it
			    if [ ${FORCE} == "1" ]; then

			        #Try for some graceful shutdown
                    ./egg-instance-stop.sh $LOGICALINSTANCEID

                    #Terminate command
                    ${EC2_HOME}/bin/ec2-terminate-instances $AMAZONINSTANCEID

                    #Delete any current line with this logicalinstanceid
                    sed -i "
                    /^${LOGICALINSTANCEID}:/ d\
                    " $AMAZONIIDSFILE

				fi
			fi
		fi	
	fi
}; done; exec 3>&-

