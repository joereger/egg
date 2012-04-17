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


        #Read Mongodbs
        MONGODBECHO=""
        exec 4<> $MONGODBSFILE; while read inmongodbsline <&4; do {
            if [ $(echo "$inmongodbsline" | cut -c1) != "#" ]; then
                MONGODBID=$(echo "$inmongodbsline" | cut -d ":" -f1)
                LOGICALINSTANCEID_D=$(echo "$inmongodbsline" | cut -d ":" -f2)
                if [ "$LOGICALINSTANCEID_D" == "$LOGICALINSTANCEID" ]; then
                    MONGODBECHO=$MONGODBECHO" mongodb"$MONGODBID
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


        DISKSPACEAVAILABLE=`ssh $HOST "df / | awk '{ print \\$4 }' | tail -n 1"`
        echo "DISKSPACEAVAILABLE=$DISKSPACEAVAILABLE"
        GIGAVAIL=$((DISKSPACEAVAILABLE / 1000000))

		

		#SPEED=`ssh $HOST 'STARTTIME=$(date +%s.%N); for i in {1..100000}; do TMPVAR=$((i/3)); done; END=$(date +%s.%N); DIFF=$(echo "$END - $STARTTIME" | bc); echo $DIFF'`
        CURRENTTIME=`TZ=EST date +"%b %d %r"`

        UPTIME=`ssh $HOST 'uptime'`
        ./log-debug.sh "Instance$LOGICALINSTANCEID $UPTIME"

        pre=`echo $UPTIME | sed -e "s/\(.*\) \(.*\), \(.*\), \(.*\)/\1/"`
        min_1=`echo $UPTIME | sed -e 's/\(.*\) \(.*\), \(.*\), \(.*\)/\2/'`
        min_5=`echo $UPTIME | sed -e 's/\(.*\) \(.*\), \(.*\), \(.*\)/\3/'`
        min_15=`echo $UPTIME | sed -e 's/\(.*\) \(.*\), \(.*\), \(.*\)/\4/'`



        ./log-debug.sh "Instance$LOGICALINSTANCEID $min_1 $min_5 $min_15"

        # bash doesn't understand floating point
        # so convert the number to an interger
        #thisloadavg=`echo $loadavg|awk -F \. '{print $1}'`

        if [ "$min_1" != "" ]; then
            if [ $DISKSPACEAVAILABLE < 1000000 ]; then
                ./pulse-update.sh "Instance${LOGICALINSTANCEID}" "LOW DISK ($min_1 $min_5 $min_15) $AMAZONINSTANCEID ${GIGAVAIL}G $TCECHO$TERECHO$APAACHEECHO$MYSQLECHO$MONGODBECHO"
            else
                ./pulse-update.sh "Instance${LOGICALINSTANCEID}" "OK ($min_1 $min_5 $min_15) $AMAZONINSTANCEID ${GIGAVAIL}G $TCECHO$TERECHO$APAACHEECHO$MYSQLECHO$MONGODBECHO"
            fi
        else
            ./pulse-update.sh "Instance${LOGICALINSTANCEID}" "SPEEDTEST EMPTY RESULT $AMAZONINSTANCEID ${GIGAVAIL}G $TCECHO$TERECHO$APAACHEECHO$MYSQLECHO$MONGODBECHO"
        fi

        echo -e "$CURRENTTIME \t$($min_1 $min_5 $min_15) \tLOGICALINSTANCEID=$LOGICALINSTANCEID \t$AMAZONINSTANCEID \t$INSTANCESIZE \t$SECURITYGROUP \t$TCECHO$TERECHO$APAACHEECHO$MYSQLECHO$MONGODBECHO"
        echo -e "$CURRENTTIME \t$($min_1 $min_5 $min_15) \tLOGICALINSTANCEID=$LOGICALINSTANCEID \t$AMAZONINSTANCEID \t$INSTANCESIZE \t$SECURITYGROUP \t$TCECHO$TERECHO$APAACHEECHO$MYSQLECHO$MONGODBECHO" >> logs/instances.speed.log




        #Check Egg (this) server
        UPTIME=`uptime`

        pre=`echo $UPTIME | sed -e "s/\(.*\) \(.*\), \(.*\), \(.*\)/\1/"`
        min_1=`echo $UPTIME | sed -e 's/\(.*\) \(.*\), \(.*\), \(.*\)/\2/'`
        min_5=`echo $UPTIME | sed -e 's/\(.*\) \(.*\), \(.*\), \(.*\)/\3/'`
        min_15=`echo $UPTIME | sed -e 's/\(.*\) \(.*\), \(.*\), \(.*\)/\4/'`

        if [ "$min_1" != "" ]; then
            ./pulse-update.sh "Egg" "OK ($min_1 $min_5 $min_15)"
        else
            ./pulse-update.sh "Egg" "SPEEDTEST EMPTY RESULT"
        fi







	fi
}; done; exec 3>&-




