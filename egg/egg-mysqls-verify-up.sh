#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

MYSQLSFILE=conf/mysqls.conf
INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi


if [ ! -f "$MYSQLSFILE" ]; then
  echo "Sorry, $MYSQLSFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

ALLISWELL=1

#Read Mysqls
while read inmysqlsline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$inmysqlsline" | cut -c1) != "#" ]; then
	
		MYSQLID=$(echo "$inmysqlsline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$inmysqlsline" | cut -d ":" -f2)

		
		#Read INSTANCESFILE    
		while read ininstancesline;
		do
			#Ignore lines that start with a comment hash mark
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
					while read amazoniidsline;
					do
						#Ignore lines that start with a comment hash mark
						if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
							LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
							if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
								AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
								HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
							fi
						fi
					done < "$AMAZONIIDSFILE"


					#MySQL Existence Check
					echo Start MySQL Check
					apachecheck=`ssh $HOST "[ -e /etc/my.cnf ] && echo 1"`
					if [ "$apachecheck" != 1 ]; then
					    ALLISWELL=0
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
                    selectcheck=`ssh $HOST "mysql -uroot -pcatalyst --silent --silent --execute='select 1+1;'"`
                    echo selectcheck=$selectcheck
					if [ "$selectcheck" != "2" ]; then
					    ALLISWELL=0
						./log-status-red.sh "MySQL$MYSQLID process not found, restarting"
						./egg-mysql-stop.sh $HOST
						./egg-mysql-configure.sh $HOST $MYSQLID
						./egg-mysql-start.sh $HOST
						./log.sh "MySQL$MYSQLID Sleeping 10 seconds for startup"
                        sleep 10
					else
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
		done < "$INSTANCESFILE"
		
	
	fi
done < "$MYSQLSFILE"

if [ "$ALLISWELL" == "1"  ]; then
    ./log-status.sh "MySQLs AllIsWell `date`"
fi
