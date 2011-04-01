#!/bin/bash

export DONTREDITSTDOUTTOLOGFILE=1
source common.sh



if [ "$1" == "" ]; then
    echo "Tail which tomcat's cache log file? (Type the number and hit enter)"
    exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
        if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
            TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
            LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
            APPNAME=$(echo "$intomcatline" | cut -d ":" -f3)
            echo "$TOMCATID - $APPNAME - LogicalInstance $LOGICALINSTANCEID"
        fi
    }; done; exec 3>&-
    read CHOSENTOMCATID
else
    CHOSENTOMCATID=$1
fi

echo "CHOSENTOMCATID=$CHOSENTOMCATID"


if [ "$CHOSENTOMCATID" != "" ]; then

    exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
        if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
            TOMCATID_B=$(echo "$intomcatline" | cut -d ":" -f1)
            LOGICALINSTANCEID_B=$(echo "$intomcatline" | cut -d ":" -f2)
            APPNAME_B=$(echo "$intomcatline" | cut -d ":" -f3)
            if [ "$CHOSENTOMCATID" == "$TOMCATID_B" ]; then

                exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
                    if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                        LOGICALINSTANCEID_C=$(echo "$amazoniidsline" | cut -d ":" -f1)
                        if [ "$LOGICALINSTANCEID_C" == "$LOGICALINSTANCEID_B" ]; then
                            AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                            HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
                            APPDIR=$APPNAME_B$CHOSENTOMCATID

                            echo "Which type of cache file? (Type the number and hit enter)"
                            echo "1 - All"
                            echo "2 - Successes"
                            echo "3 - Failures"
                            read WHICHCACHEFILE
                            if [ "$WHICHCACHEFILE" != "" ]; then
                                if [ "$WHICHCACHEFILE" == "1" ]; then
                                    ssh -t -t $HOST "tail -f --lines=500 egg/${APPDIR}/tomcat/webapps/ROOT/cache-all.log"
                                fi
                                if [ "$WHICHCACHEFILE" == "2" ]; then
                                    ssh -t -t $HOST "tail -f --lines=500 egg/${APPDIR}/tomcat/webapps/ROOT/cache-success.log"
                                fi
                                if [ "$WHICHCACHEFILE" == "3" ]; then
                                    ssh -t -t $HOST "tail -f --lines=500 egg/${APPDIR}/tomcat/webapps/ROOT/cache-fail.log"
                                fi
                            fi
                        fi
                    fi
                }; done; exec 4>&-



            fi
        fi
    }; done; exec 3>&-


fi