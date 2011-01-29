#!/bin/bash

source common.sh

INSTANCESFILE=conf/instances.conf

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi
		
#Read INSTANCESFILE   
while read ininstancesline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
		
		./egg-instance-terminate.sh $LOGICALINSTANCEID	

	fi
done < "$INSTANCESFILE"
			
