#!/bin/bash

source common.sh

INSTANCESFILE=conf/instances.conf

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi



#ec2-describe-tags -K $EC2_PRIVATE_KEY -C $EC2_CERT --filter key=Name --filter value=web*
#TAG     instance        i-b7c117db      Name    web01


${EC2_HOME}/bin/ec2-describe-tags --filter key=Name --filter value=${EC2NAMETAG} |
while read line; do
  	IID=$(echo "$line" | cut -f3)
	
	#Default to this being a rogue instance
	ISVALIDINSTANCE=0
  
  	#Read INSTANCESFILE   
	while read ininstancesline;
	do
		#Ignore lines that start with a comment hash mark
		if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
		
			LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
			SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
			INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
			AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
			ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
			
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
			
			
			#If this instance is found, mark the iid as being valid
			if [ "$AMAZONINSTANCEID" == "$IID" ]; then
				ISVALIDINSTANCE=1
			fi
		fi
	done < "$INSTANCESFILE"
  
  	if [ $ISVALIDINSTANCE == 0 ]; then
		./log-status.sh "Terminating unnecessary instance $IID $INSTANCESIZE"
		./egg-instance-terminate.sh $LOGICALINSTANCEID
	else 
		./log.sh Not terminating instance $IID
	fi
  
done 





		
