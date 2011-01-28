#!/bin/bash

source common.sh

#Kill all Instances
${EC2_HOME}/bin/ec2-describe-tags --filter key=Name --filter value=eggweb |
while read line; do
  	IID=$(echo "$line" | cut -f3)
  	echo Terminating instance ${IID}
	${EC2_HOME}/bin/ec2-terminate-instances $IID  
done 

#Create all new Instances
./egg-instances-verify-up.sh

#Create Tomcats, Deploy WARs and Start Tomcats
./egg-apps-verify-up.sh

#Create Apaches
./egg-apaches-verify-up.sh