#!/bin/bash

export DONTREDITSTDOUTTOLOGFILE=1
source common.sh



if [ "$1" == "" ]; then
    echo "Tail which tomcat's log file? (Type the number and hit enter)"
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
                            ssh -t -t $HOST "tail -f --lines=500 egg/${APPDIR}/tomcat/logs/catalina.out"


                        fi
                    fi
                }; done; exec 4>&-



            fi
        fi
    }; done; exec 3>&-


fi