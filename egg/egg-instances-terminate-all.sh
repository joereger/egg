#!/bin/bash

source common.sh

#Delete any instance tagged with EC2NAMETAG
${EC2_HOME}/bin/ec2-describe-tags --filter key=Name --filter value=${EC2NAMETAG} |
while read line; do
  	IID=$(echo "$line" | cut -f3)
  	echo "Found instance ${IID} and will terminate it... dun dun dun."
	${EC2_HOME}/bin/ec2-terminate-instances ${IID}
done

#Empty the amazoniids.conf file by copying in an empty one
cp conf/amazoniids-sample.conf conf/amazoniids.conf
			
