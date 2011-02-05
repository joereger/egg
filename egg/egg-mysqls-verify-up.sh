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
  cp data/amazoniids-sample.conf $AMAZONIIDSFILE
fi


if [ ! -f "$MYSQLSFILE" ]; then
  echo "Sorry, $MYSQLSFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

#Read APACHESFILE
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

					echo CHECKING MYSQL $INSTANCESIZE http://$HOST/

					#MySQL Existence Check
					echo Start Apache Check
					apachecheck=`ssh $HOST "[ -e /etc/my.cnf/ ] && echo 1"`
					if [ "$apachecheck" != 1 ]; then
						./egg-log-status.sh "MySQL my.cnf not found, will create"
						./egg-mysql-create.sh $HOST
						./egg-mysql-configure.sh $MYSQLID
						./egg-mysql-start.sh $HOST
					else 
						echo MySQL installation folder found
					fi
					
					#Apache Process Check
					processcheck=`ssh $HOST "[! pgrep mysql -c >/dev/null] && echo 1"`
					if [ "$processcheck" != 1 ]; then
						./egg-log-status.sh "MySQL process not found processcheck=$processcheck"
						./egg-mysql-stop.sh $HOST
						./egg-mysql-configure.sh $MYSQLID
						./egg-mysql-start.sh $HOST
					else
						echo MySQL process found
					fi



				fi
			fi
		done < "$INSTANCESFILE"
		
	
	fi
done < "$MYSQLSFILE"
