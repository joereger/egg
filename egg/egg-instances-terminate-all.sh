#!/bin/bash

source common.sh


#Run through instances.conf and try for graceful shutdowns before mass termination by tag
INSTANCESFILE=conf/instances.conf

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

while read ininstancesline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then

		LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
        ./egg-instance-terminate.sh $LOGICALINSTANCEID

	fi
done < "$INSTANCESFILE"


#Delete any instance tagged with EC2NAMETAG
${EC2_HOME}/bin/ec2-describe-tags --filter key=Name --filter value=${EC2NAMETAG} |
while read line; do
  	IID=$(echo "$line" | cut -f3)
  	export TERMINATED="terminated"
    export status=`${EC2_HOME}/bin/ec2-describe-instances ${IID} | grep INSTANCE | cut -f6`
    if [ "$status" != "$TERMINATED" ]; then
        echo "Found instance ${IID}... terminating... dun dun dun."
	    ${EC2_HOME}/bin/ec2-terminate-instances ${IID}
    else
        echo "Found instance ${IID}... already terminated."
    fi
done

#Empty the amazoniids.conf file by copying in an empty one
AMAZONIIDSFILE=data/amazoniids.conf
cp data/amazoniids.conf.sample $AMAZONIIDSFILE
