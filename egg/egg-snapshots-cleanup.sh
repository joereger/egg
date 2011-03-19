#!/bin/bash

source common.sh


exec 3<> $SNAPSHOTSFILE; while read insnapshotsline <&3; do {
	if [ $(echo "$insnapshotsline" | cut -c1) != "#" ]; then

	    EBSVOLUME=$(echo "$insnapshotsline" | cut -d ":" -f1)

        if [ "$EBSVOLUME" != "" ]; then

            ./egg-snapshot-cleanup.sh $EBSVOLUME daily
            ./egg-snapshot-cleanup.sh $EBSVOLUME weekly
            ./egg-snapshot-cleanup.sh $EBSVOLUME monthly

        fi

	fi
}; done; exec 3>&-



