#!/bin/bash

source common.sh

INSTANCESFILE=conf/instances.conf

if [ ! -f "$INSTANCESFILE" ];
then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi



#ec2-describe-tags -K $EC2_PRIVATE_KEY -C $EC2_CERT --filter key=Name --filter value=web*
#TAG     instance        i-b7c117db      Name    web01


${EC2_HOME}/bin/ec2-describe-tags --filter key=Name --filter value=eggweb |
while read line; do
  	IID=$(echo "$line" | cut -f3)
  	echo Found instance ${IID}
	
	ISVALIDINSTANCE=0
  
  	#Read INSTANCESFILE   
	while read ininstancesline;
	do
		#Ignore lines that start with a comment hash mark
		if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
		
			LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
			INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f2)
			AMAZONINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f3)
			HOST=$(echo "$ininstancesline" | cut -d ":" -f4)
			ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
			
			#If this instance is found, mark the iid as being valid
			if [ "$AMAZONINSTANCEID" == "$IID" ]; then
				ISVALIDINSTANCE=1
			fi
		fi
	done < "$INSTANCESFILE"
  
  	if [ $ISVALIDINSTANCE == 0 ]; then
		echo Terminating unnecessary instance $IID
		${EC2_HOME}/bin/ec2-terminate-instances $IID
	else 
		echo Not terminating instance $IID
	fi
  
done 





		
