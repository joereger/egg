#!/bin/bash

source common.sh

		
#Read INSTANCESFILE
 exec 3<> $INSTANCESFILE; while read line_instances_ivu <&3; do {
	if [ $(echo "$line_instances_ivu" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID=$(echo "$line_instances_ivu" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$line_instances_ivu" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$line_instances_ivu" | cut -d ":" -f3)

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




		#Read TOMCATSFILE
        TCECHO=""
        exec 4<> $TOMCATSFILE; while read intomcatline <&4; do {
            if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
                TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
                LOGICALINSTANCEID_C=$(echo "$intomcatline" | cut -d ":" -f2)
                if [ "$LOGICALINSTANCEID_C" == "$LOGICALINSTANCEID" ]; then
                    APP=$(echo "$intomcatline" | cut -d ":" -f3)
                    APPDIR=$APP$TOMCATID
                    TCECHO=$TCECHO" "$APPDIR
                fi
            fi
        }; done; exec 4>&-

        #Read Mysqls
        MYSQLECHO=""
        exec 4<> $MYSQLSFILE; while read inmysqlsline <&4; do {
            if [ $(echo "$inmysqlsline" | cut -c1) != "#" ]; then
                MYSQLID=$(echo "$inmysqlsline" | cut -d ":" -f1)
                LOGICALINSTANCEID_D=$(echo "$inmysqlsline" | cut -d ":" -f2)
                if [ "$LOGICALINSTANCEID_D" == "$LOGICALINSTANCEID" ]; then
                    MYSQLECHO=$MYSQLECHO" mysql"$MYSQLID
                fi
            fi
        }; done; exec 4>&-

        #Read Terracottas
        TERECHO=""
        exec 4<> $TERRACOTTASFILE; while read interracottas <&4; do {
            if [ $(echo "$interracottas" | cut -c1) != "#" ]; then
                TERRACOTTAID=$(echo "$interracottas" | cut -d ":" -f1)
		        LOGICALINSTANCEID_E=$(echo "$interracottas" | cut -d ":" -f2)
                if [ "$LOGICALINSTANCEID_E" == "$LOGICALINSTANCEID" ]; then
                    TERECHO=$TERECHO" terracotta"$TERRACOTTAID
                fi
            fi
        }; done; exec 4>&-

        #Read Apaches
        APAACHEECHO=""
        exec 4<> $APACHESFILE; while read inapacheline <&4; do {
            if [ $(echo "$inapacheline" | cut -c1) != "#" ]; then
                APACHEID=$(echo "$inapacheline" | cut -d ":" -f1)
		        LOGICALINSTANCEID_F=$(echo "$inapacheline" | cut -d ":" -f2)
                if [ "$LOGICALINSTANCEID_F" == "$LOGICALINSTANCEID" ]; then
                    APAACHEECHO=$APAACHEECHO" apache"$APACHEID
                fi
            fi
        }; done; exec 4>&-
		

		SPEED=`ssh $HOST 'STARTTIME=$(date +%s.%N); for i in {1..100000}; do TMPVAR=$((i/3)); done; END=$(date +%s.%N); DIFF=$(echo "$END - $STARTTIME" | bc); echo $DIFF'`
        CURRENTTIME=`TZ=EST date +"%b %d %r"`
        if [ "$SPEED" != "" ]; then
            ./pulse-update.sh "Instance${LOGICALINSTANCEID}" "OK, ${SPEED}sec $SECURITYGROUP $TCECHO$TERECHO$APAACHEECHO$MYSQLECHO"
        else
            ./pulse-update.sh "Instance${LOGICALINSTANCEID}" "SPEEDTEST EMPTY RESULT $SECURITYGROUP $TCECHO$TERECHO$APAACHEECHO$MYSQLECHO"
        fi
        echo -e "$CURRENTTIME \t$SPEED sec \tLOGICALINSTANCEID=$LOGICALINSTANCEID \t$INSTANCESIZE \t$SECURITYGROUP \t$TCECHO$TERECHO$APAACHEECHO$MYSQLECHO"
        echo -e "$CURRENTTIME \t$SPEED sec \tLOGICALINSTANCEID=$LOGICALINSTANCEID \t$INSTANCESIZE \t$SECURITYGROUP \t$TCECHO$TERECHO$APAACHEECHO$MYSQLECHO" >> logs/instances.speed.log

	fi
}; done; exec 3>&-




