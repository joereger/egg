#!/bin/bash

source common.sh

exec 3<> $INSTANCESFILE; while read line_instances_ivu <&3; do {
	if [ $(echo "$line_instances_ivu" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID=$(echo "$line_instances_ivu" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$line_instances_ivu" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$line_instances_ivu" | cut -d ":" -f3)
		AMIID=$(echo "$line_instances_ivu" | cut -d ":" -f4)
		ELASTICIP=$(echo "$line_instances_ivu" | cut -d ":" -f5)
		EBSVOLUME=$(echo "$line_instances_ivu" | cut -d ":" -f6)
		EBSDEVICENAME=$(echo "$line_instances_ivu" | cut -d ":" -f7)


        if [ "$EBSVOLUME" != "" ]; then

            ./egg-snapshot-cleanup.sh $EBSVOLUME daily
            ./egg-snapshot-cleanup.sh $EBSVOLUME weekly
            ./egg-snapshot-cleanup.sh $EBSVOLUME monthly

        fi

	fi
}; done; exec 3>&-



