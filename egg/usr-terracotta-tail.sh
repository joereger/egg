#!/bin/bash

export DONTREDITSTDOUTTOLOGFILE=1
source common.sh


if [ "$1" == "" ]; then
    echo "Tail which terracotta's log file? (Type the number and hit enter)"
    exec 3<> $TERRACOTTASFILE; while read interracottas <&3; do {
        if [ $(echo "$interracottas" | cut -c1) != "#" ]; then
            TERRACOTTAID=$(echo "$interracottas" | cut -d ":" -f1)
            LOGICALINSTANCEID=$(echo "$interracottas" | cut -d ":" -f2)
            echo "$TERRACOTTAID - Terracotta$TERRACOTTAID - LogicalInstance $LOGICALINSTANCEID"
        fi
    }; done; exec 3>&-
    read CHOSENTERRACOTTAID
else
    CHOSENTERRACOTTAID=$1
fi

echo "CHOSENTERRACOTTAID=$CHOSENTERRACOTTAID"

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

                            ssh -t -t $HOST "tail -f --lines=100 terracotta/server-logs/terracotta-server.log"

                        fi
                    fi
                }; done; exec 4>&-

            fi
        fi
    }; done; exec 3>&-


fi