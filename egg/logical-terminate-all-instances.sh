#!/bin/bash

source common.sh

INSTANCESFILE=conf/instances.conf

if [ ! -f "$INSTANCESFILE" ];
then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi
		
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
		
		echo Terminating LOGICALINSTANCEID=$LOGICALINSTANCEID $INSTANCESIZE AMAZONINSTANCEID=$AMAZONINSTANCEID HOST=$HOST ELASTICIP=$ELASTICIP
		
		${EC2_HOME}/bin/ec2-terminate-instances $AMAZONINSTANCEID
			
		#Write a record to instances.conf, blanking out amazoninstanceid and other vars
		sed -i "
		/${ininstancesline}/ c\
		$LOGICALINSTANCEID:$INSTANCESIZE:::
		" $INSTANCESFILE

	fi
done < "$INSTANCESFILE"
			
