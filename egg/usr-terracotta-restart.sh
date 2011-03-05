#!/bin/bash

source common.sh


echo "Restart which terracotta? (Type the number and hit enter)"
exec 3<> $TERRACOTTASFILE; while read interracottas <&3; do {
	if [ $(echo "$interracottas" | cut -c1) != "#" ]; then
	    TERRACOTTAID=$(echo "$interracottas" | cut -d ":" -f1)
	    LOGICALINSTANCEID=$(echo "$interracottas" | cut -d ":" -f2)
        echo "$TERRACOTTAID - Terracotta$TERRACOTTAID - LogicalInstance $LOGICALINSTANCEID"
	fi
}; done; exec 3>&-

read CHOSENTERRACOTTAID
if [ "$CHOSENTERRACOTTAID" != "" ]; then

    exec 3<> $TERRACOTTASFILE; while read interracottas <&3; do {
        if [ $(echo "$interracottas" | cut -c1) != "#" ]; then
            TERRACOTTAID=$(echo "$interracottas" | cut -d ":" -f1)
            LOGICALINSTANCEID=$(echo "$interracottas" | cut -d ":" -f2)
            if [ "$CHOSENTERRACOTTAID" == "$TERRACOTTAID" ]; then

                exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
                    if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                        LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
                        if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
                            AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                            HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)

                            #Restart this terracotta
                            echo "Stopping terracotta"
                            ./egg-terracotta-stop.sh $HOST
                            echo "Sleeping 10 seconds before starting terracotta"
                            sleep 10
                            ./egg-terracotta-start.sh $HOST $TERRACOTTAID
                            echo "Terracotta$TERRACOTTAID restarted"

                        fi
                    fi
                }; done; exec 4>&-

            fi
        fi
    }; done; exec 3>&-


fi