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
		APP=$(echo "$intomcatline" | cut -d ":" -f3)
		MEMMIN=$(echo "$intomcatline" | cut -d ":" -f4)
		MEMMAX=$(echo "$intomcatline" | cut -d ":" -f5)
		HTTPPORT=$(echo "$intomcatline" | cut -d ":" -f6)
		MAXTHREADS=$(echo "$intomcatline" | cut -d ":" -f7)
	
		#Determine APPDIR
		APPDIR=$APP$TOMCATID
		JVMROUTE=$APP$TOMCATID
		
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
					echo CHECKING $APP $INSTANCESIZE http://$HOST:$HTTPPORT/
					./egg-log-status.sh "Checking app at $APP $INSTANCESIZE http://$HOST:$HTTPPORT/"
					
					#Instance Check
					echo Start Instance Check
					export thisinstanceisup=0
					export RUNNING="running"
					export status=`${EC2_HOME}/bin/ec2-describe-instances $AMAZONINSTANCEID | grep INSTANCE | cut -f6`
					if [ $status == ${RUNNING} ]; then
						echo "Instance running"
						export thisinstanceisup=1  	


					    #Tomcat Check
                        echo "$APPDIR Start Tomcat Installation Check "
                        tomcatcheck=`ssh $HOST "[ -d ./egg/$APPDIR/tomcat/ ] && echo 1"`
                        if [ "$tomcatcheck" != 1 ]; then
                            ./egg-log-status.sh "$APPDIR Tomcat not found, will create"
                            ./egg-tomcat-create.sh $HOST $APP $APPDIR $TOMCATID
                        else
                            echo "Tomcat found"
                        fi

                        #WAR File Check
                        #@TODO WAR file date checking to see if instance has latest (although maybe not a good idea if i'm planning on uploading files because partial upload may trigger deploy)
                        echo "$APPDIR Start WAR File Check"
                        warcheck=`ssh $HOST "[ -e ./egg/$APPDIR/ROOT.war ] && echo 1"`
                        if [ "$warcheck" != 1 ]; then
                            ./egg-log-status.sh "$APPDIR WAR not found, will deploy"
                            ./egg-tomcat-deploy-war.sh $HOST $APP $APPDIR
                        else
                            echo "$APPDIR WAR found"
                        fi


                        #Need to bounce flag
                        NEEDTOBOUNCETOMCAT=0
                        #Update server.xml and instanceprops in data/ dir
                        ./egg-tomcat-update-serverxml.sh $HOST $APP $APPDIR $HTTPPORT $MAXTHREADS $JVMROUTE $TOMCATID
                        ./egg-tomcat-update-props.sh $HOST $APP $APPDIR $TOMCATID
                        #Download the latest server.xml and instance.props
                        rm -f data/$APP.tomcatid$TOMCATID.server.xml.remote
                        rm -f data/$APP.tomcatid$TOMCATID.instance.props.remote
                        scp ec2-user@$HOST:~/egg/$APPDIR/tomcat/conf/server.xml data/$APP.tomcatid$TOMCATID.server.xml.remote
                        scp ec2-user@$HOST:~/egg/$APPDIR/tomcat/webapps/ROOT/conf/instance.props data/$APP.tomcatid$TOMCATID.instance.props.remote
                        #Compare server.xml local to remote and send if anything's changed
                        if  diff data/$APP.tomcatid$TOMCATID.server.xml.tmp data/$APP.tomcatid$TOMCATID.server.xml.remote >/dev/null ; then
                            echo "data/$APP.tomcatid$TOMCATID.server.xml.tmp is the same as data/$APP.tomcatid$TOMCATID.server.xml.remote"
                        else
                            NEEDTOBOUNCETOMCAT=1
                            echo "data/$APP.tomcatid$TOMCATID.server.xml.tmp is different than data/$APP.tomcatid$TOMCATID.server.xml.remote"
                            #Make sure /conf exists
                            ssh -t -t $HOST "mkdir -p egg/$APPDIR/tomcat/conf"
                            #Copy latest to remote Tomcat
                            ssh -t -t $HOST "rm -f egg/$APPDIR/tomcat/conf/server.xml"
                            scp data/$APP.tomcatid$TOMCATID.server.xml.tmp ec2-user@$HOST:~/egg/$APPDIR/tomcat/conf/server.xml
                        fi
                        #Compare instance.props local to remote and send if anything's changed
                        if  diff data/$APP.tomcatid$TOMCATID.instance.props.tmp data/$APP.tomcatid$TOMCATID.instance.props.remote >/dev/null ; then
                            echo "data/$APP.tomcatid$TOMCATID.instance.props.tmp is the same as data/$APP.tomcatid$TOMCATID.instance.props.remote"
                        else
                            NEEDTOBOUNCETOMCAT=1
                            echo "data/$APP.tomcatid$TOMCATID.instance.props.tmp is different than data/$APP.tomcatid$TOMCATID.instance.props.remote"
                            #Make sure /conf exists
                            ssh -t -t $HOST "mkdir -p egg/$APPDIR/tomcat/webapps/ROOT/conf"
                            #Copy latest to remote Tomcat
                            ssh -t -t $HOST "rm -f egg/$APPDIR/tomcat/webapps/ROOT/conf/instance.props"
                            scp data/$APP.tomcatid$TOMCATID.instance.props.tmp ec2-user@$HOST:~/egg/$APPDIR/tomcat/webapps/ROOT/conf/instance.props
                        fi
                        #If anything's changed, bounce tomcat
                        if [ "$NEEDTOBOUNCETOMCAT" == "1" ]; then
                            ./egg-tomcat-stop.sh $HOST $APPDIR
                            ./egg-tomcat-start.sh $HOST $APPDIR $MEMMIN $MEMMAX
                            ./egg-log-status.sh "Sleeping 30 sec for $APP Tomcat$TOMCATID to come up"
                            sleep 30
                         fi

                        #HTTP Check which will restart tomcat instance if necessary
                        ./egg-tomcat-check.sh $HOST $APP $APPDIR $TOMCATID

					else
						./egg-log-status.sh "$APPDIR Instance $AMAZONINSTANCEID not running"
						export thisinstanceisup=0
					fi
					

				fi
			fi
		done < "$INSTANCESFILE"
		
	
	fi
done < "$TOMCATSFILE"
