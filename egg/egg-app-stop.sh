#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

APP=$1

TOMCATSFILE=conf/tomcats.conf
INSTANCESFILE=conf/instances.conf


if [ ! -f "$TOMCATSFILE" ];
then
  echo "Sorry, $TOMCATSFILE does not exist."
  exit 1
fi

if [ ! -f "$INSTANCESFILE" ];
then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

#Read TOMCATSFILE
while read intomcatline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
	
		TOMCATID_A=$(echo "$intomcatline" | cut -d ":" -f1)
		LOGICALINSTANCEID_A=$(echo "$intomcatline" | cut -d ":" -f2)
		APPNAME_A=$(echo "$intomcatline" | cut -d ":" -f3)
		MEMMIN_A=$(echo "$intomcatline" | cut -d ":" -f4)
		MEMMAX_A=$(echo "$intomcatline" | cut -d ":" -f5)
		HTTPPORT_A=$(echo "$intomcatline" | cut -d ":" -f6)
	
		if [ "$APPNAME_A" == "$APP" ]; then
		
			echo --FOUND $APP TOMCAT INSTANCE--
			echo TOMCATID=$TOMCATID_A
			echo LOGICALINSTANCEID=$LOGICALINSTANCEID_A
			echo APPNAME=$APPNAME_A
			echo MEMMIN=$MEMMIN_A
			echo MEMMAX=$MEMMAX_A
			echo HTTPPORT=$HTTPPORT_A	
		
			#Determine APPDIR
			APPDIR=$APPNAME_A$TOMCATID_A
			echo APPDIR=$APPDIR
			
			#Read INSTANCESFILE    
			while read ininstancesline;
			do
				#Ignore lines that start with a comment hash mark
				if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
				
					LOGICALINSTANCEID_B=$(echo "$ininstancesline" | cut -d ":" -f1)
					INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f2)
					AMIID=$(echo "$ininstancesline" | cut -d ":" -f3)
					ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f4)
					
					#Read AMAZONIIDSFILE   
					while read amazoniidsline;
					do
						#Ignore lines that start with a comment hash mark
						if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
							LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
							if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
								AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f3)
								HOST=$(echo "$amazoniidsline" | cut -d ":" -f4)
							fi
						fi
					done < "$AMAZONIIDSFILE"
					
					if [ "$LOGICALINSTANCEID_B" == "$LOGICALINSTANCEID_A" ]; then
						echo FOUND LOGICALINSTANCE $LOGICALINSTANCEID_B $INSTANCESIZE $HOST
					fi
				fi
			done < "$INSTANCESFILE"
			
			#Stop this instance
			if [ "$HOST" != "" ]; then
				./egg-tomcat-stop.sh $HOST $APPDIR
			fi
		
		fi
	fi
done < "$TOMCATSFILE"







