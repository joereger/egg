#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: LOGICALINSTANCEID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a LOGICALINSTANCEID"; exit; fi

LOGICALINSTANCEID=$1

		
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

                ./pulse-update.sh "Instance$LOGICALINSTANCEID" "STOPPING MYSQL"
                #Try for some graceful shutdown of MySQL
                ./egg-mysql-stop.sh $HOST

                #Stop command
                ${EC2_HOME}/bin/ec2-stop-instances $AMAZONINSTANCEID

                # Loop until the status changes to .stopped.
                ./pulse-update.sh "Instance$LOGICALINSTANCEID" "STOPPING, WAIT 30 SEC"
                sleep 30
                echo Stopping instance ${AMAZONINSTANCEID}
                export STOPPED="stopped"
                export done="false"
                while [ $done == "false" ]
                do
                   export status=`${EC2_HOME}/bin/ec2-describe-instances ${AMAZONINSTANCEID} | grep INSTANCE | cut -f6`
                   if [ $status == ${STOPPED} ]; then
                      export done="true"
                   else
                      ./pulse-update.sh "Instance$LOGICALINSTANCEID" "STOPPING, WAIT 10 SEC"
                      echo Waiting...
                      sleep 10
                   fi
                done
                ./pulse-update.sh "Instance$LOGICALINSTANCEID" "STOPPED"
                echo Instance ${AMAZONINSTANCEID} is stopped
					

			
				
			fi
		fi	
	fi
}; done; exec 3>&-












