#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

TOMCATSFILE=conf/tomcats.conf
INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf

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

#Read TOMCATSFILE
while read intomcatline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
	
		TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
		APPNAME=$(echo "$intomcatline" | cut -d ":" -f3)
		MEMMIN=$(echo "$intomcatline" | cut -d ":" -f4)
		MEMMAX=$(echo "$intomcatline" | cut -d ":" -f5)
		HTTPPORT=$(echo "$intomcatline" | cut -d ":" -f6)
		MAXTHREADS=$(echo "$intomcatline" | cut -d ":" -f7)
	
		#Determine APPDIR
		APPDIR=$APPNAME$TOMCATID
		JVMROUTE=$APPNAME$TOMCATID
		
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
				
				
					echo "  "
					echo CHECKING $APPNAME $INSTANCESIZE http://$HOST:$HTTPPORT/
					./egg-log-status.sh "Checking app at $APPNAME $INSTANCESIZE http://$HOST:$HTTPPORT/"
					
					#Instance Check
					echo Start Instance Check
					export thisinstanceisup=0
					export RUNNING="running"
					export status=`${EC2_HOME}/bin/ec2-describe-instances $AMAZONINSTANCEID | grep INSTANCE | cut -f6`
					if [ $status == ${RUNNING} ]; then
						echo "Instance running"
						export thisinstanceisup=1  	


					    #Tomcat Check
                        echo Start Tomcat Check
                        tomcatcheck=`ssh $HOST "[ -d ./egg/$APPDIR/tomcat/ ] && echo 1"`
                        if [ "$tomcatcheck" != 1 ]; then
                            ./egg-log-status.sh "Tomcat not found, will create"
                            ./egg-tomcat-create.sh $HOST $APPDIR
                            ./egg-tomcat-update-serverxml.sh $HOST $APPNAME $APPDIR $HTTPPORT $MAXTHREADS $JVMROUTE $TOMCATID
                            ./egg-tomcat-update-props.sh $HOST $APPNAME $APPDIR $TOMCATID
                        else
                            echo Tomcat found
                        fi

                        #WAR File Check
                        echo Start WAR File Check
                        warcheck=`ssh $HOST "[ -e ./egg/$APPDIR/ROOT.war ] && echo 1"`
                        if [ "$warcheck" != 1 ]; then
                            ./egg-log-status.sh "WAR not found, will deploy"
                            ./egg-tomcat-deploy-war.sh $HOST $APPNAME $APPDIR
                            ./egg-tomcat-update-props.sh $HOST $APPNAME $APPDIR $TOMCATID
                        else
                            echo WAR found
                        fi

                        #Instance.props File Check
                        echo Start Instance.props File Check
                        propscheck=`ssh $HOST "[ -e ./egg/$APPDIR//tomcat/webapps/ROOT/conf/instance.props ] && echo 1"`
                        if [ "$propscheck" != 1 ]; then
                            ./egg-log-status.sh "Instance.props not found, will send"
                            ./egg-tomcat-update-props.sh $HOST $APPNAME $APPDIR $TOMCATID
                        else
                            echo Instance.props found
                        fi

                        #HTTP Check
                        echo Start HTTP Check
                        url="http://$HOST:$HTTPPORT/"
                        retries=1
                        timeout=60
                        status=`wget -t 1 -T 60 $url 2>&1 | egrep "HTTP" | awk {'print $6'}`
                        if [ "$status" == "200" ]; then
                            echo HTTP 200 found
                        else
                            ./egg-log-status.sh "HTTP 200 not found, will stop/start tomcat"
                            ./egg-tomcat-stop.sh $HOST $APPDIR
                            ./egg-tomcat-update-props.sh $HOST $APPNAME $APPDIR $TOMCATID
                            ./egg-tomcat-start.sh $HOST $APPDIR $MEMMIN $MEMMAX
                        fi


					else
						./egg-log-status.sh "Instance not running"
						export thisinstanceisup=0
					fi
					

				fi
			fi
		done < "$INSTANCESFILE"
		
	
	fi
done < "$TOMCATSFILE"
