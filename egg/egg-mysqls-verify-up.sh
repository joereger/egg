#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

ALLISWELL=1

#Read Mysqls
exec 3<> $MYSQLSFILE; while read inmysqlsline <&3; do {
	if [ $(echo "$inmysqlsline" | cut -c1) != "#" ]; then
	
		MYSQLID=$(echo "$inmysqlsline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$inmysqlsline" | cut -d ":" -f2)

		
		#Read INSTANCESFILE    
		exec 4<> $INSTANCESFILE; while read ininstancesline <&4; do {
			if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
			
				LOGICALINSTANCEID_B=$(echo "$ininstancesline" | cut -d ":" -f1)
				SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
				INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
				AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
				ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
				
				if [ "$LOGICALINSTANCEID_B" == "$LOGICALINSTANCEID" ]; then
				
					#Read AMAZONIIDSFILE
					AMAZONINSTANCEID=""
					HOST=""
					exec 5<> $AMAZONIIDSFILE; while read amazoniidsline <&5; do {
						if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
							LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
							if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
								AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
								HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
							fi
						fi
					}; done; exec 5>&-


					#MySQL Existence Check
					echo "Start MySQL$MYSQLID Check"
					apachecheck=`ssh $HOST "[ -e /etc/my.cnf ] && echo 1"`
					if [ "$apachecheck" != 1 ]; then
					    ALLISWELL=0
					    ./pulse-update.sh "MySQL$MYSQLID" "INSTALLING"
						./log-status-red.sh "MySQL$MYSQLID my.cnf not found, installing"
						./egg-mysql-create.sh $HOST
						./egg-mysql-configure.sh $HOST $MYSQLID
						./egg-mysql-start.sh $HOST
						./log.sh "MySQL$MYSQLID Sleeping 10 seconds for startup"
                        sleep 10
					else 
						echo "MySQL$MYSQLID installation folder found"
					fi
					
					#MySQL Process Check
                    #This line very finickey...
                    processcheck=`ssh $HOST "[ -n \"\\\`pgrep mysql\\\`\" ] && echo 1"`
                    echo processcheck=$processcheck
					if [ "$processcheck" != 1 ]; then
					    ALLISWELL=0
					    ./pulse-update.sh "MySQL$MYSQLID" "RESTARTING"
					    ./mail.sh "MySQL$MYSQLID process not found, restarting" "where mah process at"
						./log-status-red.sh "MySQL$MYSQLID process not found, restarting"
						./egg-mysql-stop.sh $HOST
						./egg-mysql-configure.sh $HOST $MYSQLID
						./egg-mysql-start.sh $HOST
                       ./log.sh "MySQL$MYSQLID Sleeping 10 seconds for startup"
                       sleep 10
					else
						./log.sh "MySQL$MYSQLID process found"
					fi




                    #MySQL Select Check
                    #This line very finickey...
                    STARTTIME=$(date +%s.%N);
                    selectcheck=`ssh $HOST "mysql -uroot -pcatalyst --silent --silent --execute='select 1+1;'"`
                    ENDTIME=$(date +%s.%N);
                    DIFFTIME=$(echo "$ENDTIME - $STARTTIME" | bc);
                    echo selectcheck=$selectcheck
					if [ "$selectcheck" != "2" ]; then
					    ALLISWELL=0
					    ./pulse-update.sh "MySQL$MYSQLID" "RESTARTING"
					    ./mail.sh "MySQL$MYSQLID fails select check, restarting" "select me"
						./log-status-red.sh "MySQL$MYSQLID fails select check, restarting"
						./egg-mysql-stop.sh $HOST
						./egg-mysql-configure.sh $HOST $MYSQLID
						./egg-mysql-start.sh $HOST
						./log.sh "MySQL$MYSQLID Sleeping 10 seconds for startup"
                        sleep 10
					else
					    ./pulse-update.sh "MySQL$MYSQLID" "OK, ${DIFFTIME}sec"
						./log.sh "MySQL$MYSQLID select check passes"
					fi



					#mysql -uroot -pcatalyst --silent --silent --database=whocelebstweet --execute='select count(*) from error;'




                    #DBS=`mysql -uroot  -e"show databases"`
                    #for b in $DBS ;
                    #do
                    #        mysql -uroot -e"show tables from $b"
                    #done


				fi
			fi
		}; done; exec 4>&-
		
	
	fi
}; done; exec 3>&-

if [ "$ALLISWELL" == "1"  ]; then
    ./log-status.sh "MySQLs AllIsWell `date`"
fi
