#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: TOMCATID RESTARTIFCONFIGHASCHANGED"; exit; fi
if [ "$1" == "" ]; then echo "Must provide an TOMCATID"; exit; fi
#if [ "$2" == "" ]; then echo "Must provide an RESTARTIFCONFIGHASCHANGED"; exit; fi

TOMCATID=$1
RESTARTIFCONFIGHASCHANGED=$2  #Set to "RESTARTIFCONFIGHASCHANGED" to restart if config has changed


#Read TOMCATSFILE
exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
	if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then
	
		TOMCATID_A=$(echo "$intomcatline" | cut -d ":" -f1)
		LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
		APP=$(echo "$intomcatline" | cut -d ":" -f3)
		MEMMIN=$(echo "$intomcatline" | cut -d ":" -f4)
		MEMMAX=$(echo "$intomcatline" | cut -d ":" -f5)
		MAXTHREADS=$(echo "$intomcatline" | cut -d ":" -f6)
		HTTPPORT=$((8100+$TOMCATID))


	    if [ "$TOMCATID_A" == "$TOMCATID" ]; then

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
                                ./log.sh "$APPDIR server.xml local is the SAME as remote"
                            else
                                NEEDTOBOUNCETOMCAT=1
                                ./log.sh "$APPDIR server.xml local is the DIFFERENT than remote"
                                #Make sure /conf exists
                                #ssh -t -t $HOST "mkdir -p egg/$APPDIR/tomcat/conf"
                                uselessjibberishvar=`ssh $HOST "mkdir -p egg/$APPDIR/tomcat/conf"`
                                #Copy latest to remote Tomcat
                                #ssh -t -t $HOST "rm -f egg/$APPDIR/tomcat/conf/server.xml"
                                uselessjibberishvar=`ssh $HOST "rm -f egg/$APPDIR/tomcat/conf/server.xml"`
                                scp data/$APP.tomcatid$TOMCATID.server.xml.tmp ec2-user@$HOST:~/egg/$APPDIR/tomcat/conf/server.xml
                            fi
                            #Compare instance.props local to remote and send if anything's changed
                            if  diff data/$APP.tomcatid$TOMCATID.instance.props.tmp data/$APP.tomcatid$TOMCATID.instance.props.remote >/dev/null ; then
                                ./log.sh "$APPDIR instance.props local is the SAME as remote"
                            else
                                NEEDTOBOUNCETOMCAT=1
                                ./log.sh "$APPDIR instance.props local is the DIFFERENT than remote"
                                #Make sure /conf exists
                                #ssh -t -t $HOST "mkdir -p egg/$APPDIR/tomcat/webapps/ROOT/conf"
                                uselessjibberishvar=`ssh $HOST "mkdir -p egg/$APPDIR/tomcat/webapps/ROOT/conf"`
                                #Copy latest to remote Tomcat
                                #ssh -t -t $HOST "rm -f egg/$APPDIR/tomcat/webapps/ROOT/conf/instance.props"
                                uselessjibberishvar=`ssh $HOST "rm -f egg/$APPDIR/tomcat/webapps/ROOT/conf/instance.props"`
                                scp data/$APP.tomcatid$TOMCATID.instance.props.tmp ec2-user@$HOST:~/egg/$APPDIR/tomcat/webapps/ROOT/conf/instance.props
                            fi
                            #If anything's changed, bounce tomcat
                            if [ "$NEEDTOBOUNCETOMCAT" == "1" ]; then
                                if [ "$RESTARTIFCONFIGHASCHANGED" == "RESTARTIFCONFIGHASCHANGED" ]; then
                                    ./log.sh "Bouncing Tomcat $APPDIR to update props"
                                    ./egg-tomcat-stop.sh $HOST $APPDIR
                                    ./egg-tomcat-start.sh $TOMCATID $HOST $APPDIR $MEMMIN $MEMMAX
                                    ./log-status.sh "Bounced Tomcat ${APPDIR} to update props, sleeping 30 sec for it to come up"
                                    #Reset Check status by deleting any line for this tomcatid
                                    sed -i "
                                    /^${TOMCATID}:/ d\
                                    " $CHECKTOMCATSFILE
                                    #Sleep for app to come up
                                    sleep 30
                                fi
                             fi



                    fi
                fi
            }; done; exec 4>&-
	    fi
	
	fi
}; done; exec 3>&-



