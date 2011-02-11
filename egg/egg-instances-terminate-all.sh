#!/bin/bash

source common.sh

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
