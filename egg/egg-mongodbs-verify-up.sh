#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

ALLISWELL=1

#Read MONGODBs
exec 3<> $MONGODBSFILE; while read inmongodbsline <&3; do {
	if [ $(echo "$inmongodbsline" | cut -c1) != "#" ]; then

	    ALLISWELL=1
		MONGODBID=$(echo "$inmongodbsline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$inmongodbsline" | cut -d ":" -f2)

		
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


					#MONGODB Existence Check
					echo "Start MONGODB$MONGODBID Check"
					apachecheck=`ssh $HOST "[ -e /home/ec2-user/mongodb-linux-x86_64-2.0.4 ] && echo 1"`
					if [ "$apachecheck" != 1 ]; then
					    ALLISWELL=0
					    ./pulse-update.sh "MONGODB$MONGODBID" "INSTALLING"
						./log-status-red.sh "MONGODB$MONGODBID /home/ec2-user/mongodb-linux-x86_64-2.0.4 not found, installing"
						./egg-mongodb-create.sh $HOST
						./egg-mongodb-configure.sh $HOST $MONGODBID
						./egg-mongodb-start.sh $HOST
						./log.sh "MONGODB$MONGODBID Sleeping 10 seconds for startup"
                        sleep 10
					else
						echo "MONGODB$MONGODBID installation folder found"
					fi
					
					#MySQL Process Check
                    #This line very finickey...
                    processcheck=`ssh $HOST "[ -n \"\\\`pgrep mongo\\\`\" ] && echo 1"`
                    echo processcheck=$processcheck
					if [ "$processcheck" != 1 ]; then
					    ALLISWELL=0
					    ./pulse-update.sh "MONGO$MONGODBID" "RESTARTING"
					    ./mail.sh "MONGO$MONGODBID process not found, restarting" "where mah process at"
						./log-status-red.sh "MONGO$MONGODBID process not found, restarting"
						./egg-mongodb-stop.sh $HOST
						./egg-mongodb-configure.sh $HOST $MONGODBID
						./egg-mongodb-start.sh $HOST
                       ./log.sh "MONGO$MONGODBID Sleeping 10 seconds for startup"
                       sleep 10
					else
						./log.sh "MONGO$MONGODBID process found"
					fi




#                    #MySQL Select Check
#                    #This line very finickey...
#                    STARTTIME=$(date +%s.%N);
#                    selectcheck=`ssh $HOST "mysql -uroot -pcatalyst --silent --silent --execute='select 1+1;'"`
#                    ENDTIME=$(date +%s.%N);
#                    DIFFTIME=$(echo "$ENDTIME - $STARTTIME" | bc);
#                    echo selectcheck=$selectcheck
#					if [ "$selectcheck" != "2" ]; then
#					    ALLISWELL=0
#					    ./pulse-update.sh "MySQL$MONGODBID" "RESTARTING"
#					    ./mail.sh "MySQL$MONGODBID fails select check, restarting" "select me"
#						./log-status-red.sh "MySQL$MONGODBID fails select check, restarting"
#						./egg-mysql-stop.sh $HOST
#						./egg-mysql-configure.sh $HOST $MONGODBID
#						./egg-mysql-start.sh $HOST
#						./log.sh "MySQL$MONGODBID Sleeping 10 seconds for startup"
#                        sleep 10
#					else
#					    ./pulse-update.sh "MySQL$MONGODBID" "OK ${DIFFTIME:0:4}s"
#						./log.sh "MySQL$MONGODBID select check passes"
#					fi



					#mysql -uroot -pcatalyst --silent --silent --database=whocelebstweet --execute='select count(*) from error;'




                    #DBS=`mysql -uroot  -e"show databases"`
                    #for b in $DBS ;
                    #do
                    #        mysql -uroot -e"show tables from $b"
                    #done


				fi
			fi
		}; done; exec 4>&-


        if [ "$ALLISWELL" == "1"  ]; then
            ./log-status.sh "MONGODBs AllIsWell `date`"
            ./pulse-update.sh "MONGODB$MONGODBID" "OK"
        fi

		
	
	fi
}; done; exec 3>&-

