#!/bin/bash

source common.sh


echo "Restart which MySQL? (Type the number and hit enter)"
exec 3<> $MYSQLSFILE; while read inmysqls <&3; do {
	if [ $(echo "$inmysqls" | cut -c1) != "#" ]; then
	    MYSQLID=$(echo "$inmysqls" | cut -d ":" -f1)
	    LOGICALINSTANCEID=$(echo "$inmysqls" | cut -d ":" -f2)
        echo "$MYSQLID - MySQL$MYSQLID - LogicalInstance $LOGICALINSTANCEID"
	fi
}; done; exec 3>&-

read CHOSENMYSQLID
if [ "$CHOSENMYSQLID" != "" ]; then

    exec 3<> $MYSQLSFILE; while read inmysqls <&3; do {
        if [ $(echo "$inmysqls" | cut -c1) != "#" ]; then
            MYSQLID=$(echo "$inmysqls" | cut -d ":" -f1)
            LOGICALINSTANCEID=$(echo "$inmysqls" | cut -d ":" -f2)
            if [ "$CHOSENMYSQLID" == "$MYSQLID" ]; then

                exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
                    if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
                        LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
                        if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
                            AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
                            HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)

                            #Restart this mysql
                            echo "Stopping MySQL$MYSQLID"
                            ./pulse-update.sh "MySQL$MYSQLID" "Stopping"
                            ./egg-mysql-stop.sh $HOST
                            echo "Sleeping 1 second before starting MySQL$MYSQLID"
                            sleep 1
                            ./pulse-update.sh "MySQL$MYSQLID" "Starting"
                            ./egg-mysql-start.sh $HOST
                            echo "MySQL$MYSQLID restarted"
                            ./pulse-update.sh "MySQL$MYSQLID" "Restarted"

                        fi
                    fi
                }; done; exec 4>&-

            fi
        fi
    }; done; exec 3>&-


fi