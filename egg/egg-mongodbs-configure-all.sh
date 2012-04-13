#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE:"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

#Read MONGODBSFILE
exec 3<> $MONGODBSFILE; while read inmongodbsfile <&3; do {
	if [ $(echo "$inmongodbsfile" | cut -c1) != "#" ]; then
	
		MONGODBID=$(echo "$inmongodbsfile" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$inmongodbsfile" | cut -d ":" -f2)

		#Read AMAZONIIDSFILE
        AMAZONINSTANCEID=""
        HOST=""
        exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
            if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
                if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
                    AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                    HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
                fi
            fi
        }; done; exec 4>&-

		./pulse-update.sh "MONGODB$MONGODBID" "CHECKING CONFIG"
		./egg-mongodb-configure.sh $HOST $MONGODBID
		./pulse-update.sh "MONGODB$MONGODBID" "DONE CHECKING CONFIG"

	fi
}; done; exec 3>&-
