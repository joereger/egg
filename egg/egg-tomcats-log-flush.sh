#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

TOMCATSFILE=conf/tomcats.conf
INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf
CHECKTOMCATSFILE=data/check.tomcats


if [ ! -f "$CHECKTOMCATSFILE" ]; then
  echo "$CHECKTOMCATSFILE does not exist so creating it."
  cp $CHECKTOMCATSFILE.sample $CHECKTOMCATSFILE
fi

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi

if [ ! -f "$TOMCATSFILE" ]; then
  echo "Sorry, $TOMCATSFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

#Used to determine if all is well
ALLISWELL=1

#Read TOMCATSFILE
exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
	if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
	
		TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
		APP=$(echo "$intomcatline" | cut -d ":" -f3)
		MEMMIN=$(echo "$intomcatline" | cut -d ":" -f4)
		MEMMAX=$(echo "$intomcatline" | cut -d ":" -f5)
		MAXTHREADS=$(echo "$intomcatline" | cut -d ":" -f6)
		HTTPPORT=$((8100+$TOMCATID))
	
		#Determine APPDIR
		APPDIR=$APP$TOMCATID
		JVMROUTE=$APP$TOMCATID
		
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
				
				

                    #Delete logs for this tomcat
                    ./egg-tomcat-log-flush.sh $TOMCATID $HOST $APPDIR $MEMMIN $MEMMAX

					


				fi
			fi
		}; done; exec 4>&-
		
	
	fi
}; done; exec 3>&-

./log.sh "Done processing Tomcats"


if [ "$ALLISWELL" == "1" ]; then
    ./log-status.sh "Tomcats AllIsWell `date`"
fi
