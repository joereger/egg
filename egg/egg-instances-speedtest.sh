#!/bin/bash

source common.sh

INSTANCESFILEIVU=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$INSTANCESFILEIVU" ]; then
  echo "Sorry, $INSTANCESFILEIVU does not exist."
  exit 1
fi

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi


		
#Read INSTANCESFILE
 exec 3<> $INSTANCESFILEIVU; while read line_instances_ivu <&3; do {
	if [ $(echo "$line_instances_ivu" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID=$(echo "$line_instances_ivu" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$line_instances_ivu" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$line_instances_ivu" | cut -d ":" -f3)

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
		

		SPEED=`ssh $HOST 'STARTTIME=$(date +%s.%N); for i in {1..100000}; do TMPVAR=$((i/3)); done; END=$(date +%s.%N); DIFF=$(echo "$END - $STARTTIME" | bc); echo $DIFF'`
        echo "LOGICALINSTANCEID=$LOGICALINSTANCEID SPEED=$SPEED $INSTANCESIZE $SECURITYGROUP"
        echo "LOGICALINSTANCEID=$LOGICALINSTANCEID SPEED=$SPEED $INSTANCESIZE $SECURITYGROUP" >> logs/instances.speed.log

	fi
}; done; exec 3>&-




