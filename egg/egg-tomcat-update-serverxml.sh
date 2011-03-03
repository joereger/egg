#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APP APPDIR HTTPPORT MAXTHREADS JVMROUTE TOMCATID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APP"; exit; fi
if [ "$3" == "" ]; then echo "Must provide an APPDIR"; exit; fi
if [ "$4" == "" ]; then echo "Must provide an HTTPPORT"; exit; fi
if [ "$5" == "" ]; then echo "Must provide a MAXTHREADS"; exit; fi
if [ "$6" == "" ]; then echo "Must provide a JVMROUTE"; exit; fi
if [ "$7" == "" ]; then echo "Must provide a TOMCATID"; exit; fi

HOST=$1
APP=$2
APPDIR=$3
HTTPPORT=$4
MAXTHREADS=$5
JVMROUTE=$6
TOMCATID=$7



#Read TOMCATSFILE
exec 3<> $TOMCATSFILE; while read intomcatline <&3; do {
	if [ $(echo "$intomcatline" | cut -c1) != "#" ]; then

	    TOMCATID_TMP=$(echo "$intomcatline" | cut -d ":" -f1)

	    if [ "$TOMCATID_TMP" == "$TOMCATID" ]; then

            #TOMCATID=$(echo "$intomcatline" | cut -d ":" -f1)
            LOGICALINSTANCEID=$(echo "$intomcatline" | cut -d ":" -f2)
            APPNAME=$(echo "$intomcatline" | cut -d ":" -f3)
            MEMMIN=$(echo "$intomcatline" | cut -d ":" -f4)
            MEMMAX=$(echo "$intomcatline" | cut -d ":" -f5)
            MAXTHREADS=$(echo "$intomcatline" | cut -d ":" -f6)
            JVMROUTE=$APPNAME$TOMCATID
            HTTPPORT=$((8100+$TOMCATID))

		fi

	fi
}; done; exec 3>&-




#I can put tomcatid23.server.xml into /conf/apps/$APPNAME/ to override default base server.xml
SERVERXMLTOUSE=conf/tomcat/default.server.xml
if [ -e conf/apps/$APP/tomcatid$TOMCATID.server.xml ]; then
	./log.sh "conf/apps/$APP/tomcatid$TOMCATID.server.xml exists"
    SERVERXMLTOUSE=conf/apps/$APP/tomcatid$TOMCATID.server.xml
else
	./log-debug.sh "conf/apps/$APP/tomcatid$TOMCATID.server.xml not found, using default server.xml"
fi

#Make a copy of the base file to use
cp $SERVERXMLTOUSE data/$APP.tomcatid$TOMCATID.server.xml.tmp

#Replace key elements
sed -i "s/\[MAXTHREADS\]/$MAXTHREADS/g" data/$APP.tomcatid$TOMCATID.server.xml.tmp
sed -i "s/\[HTTPPORT\]/$HTTPPORT/g" data/$APP.tomcatid$TOMCATID.server.xml.tmp
sed -i "s/\[JVMROUTE\]/$JVMROUTE/g" data/$APP.tomcatid$TOMCATID.server.xml.tmp

#Transfer to egg/$APPDIR/tomcat/conf/server.xml on $HOST
#scp data/$APP.tomcatid$TOMCATID.server.xml.tmp ec2-user@$HOST:server.xml
#ssh -t -t $HOST "sudo cp server.xml egg/$APPDIR/tomcat/conf/server.xml"
#ssh -t -t $HOST "rm -f server.xml"


#Download the latest file
rm -f data/$APP.tomcatid$TOMCATID.server.xml.remote
scp ec2-user@$HOST:~/egg/$APPDIR/tomcat/conf/server.xml data/$APP.tomcatid$TOMCATID.server.xml.remote


##Determine whether this new config is different than the latest
#if  diff data/$APP.tomcatid$TOMCATID.server.xml.tmp data/$APP.tomcatid$TOMCATID.server.xml.remote >/dev/null ; then
#    echo "data/$APP.tomcatid$TOMCATID.server.xml.tmp is the same as data/$APP.tomcatid$TOMCATID.server.xml.remote"
#else
#    echo "data/$APP.tomcatid$TOMCATID.server.xml.tmp is different than data/$APP.tomcatid$TOMCATID.server.xml.remote"
#
#    #Make sure /conf exists
#    ssh -t -t $HOST "mkdir -p egg/$APPDIR/tomcat/conf"
#
#    #Copy latest to remote Tomcat
#    ssh -t -t $HOST "rm -f egg/$APPDIR/tomcat/conf/server.xml"
#    scp data/$APP.tomcatid$TOMCATID.server.xml.tmp ec2-user@$HOST:~/egg/$APPDIR/tomcat/conf/server.xml
#
#    #Bounce Tomcat
#    ./egg-tomcat-stop.sh $HOST $APPDIR
#    ./egg-tomcat-start.sh $TOMCATID $HOST $APPDIR $MEMMIN $MEMMAX
#fi






##Build up the tags that need to be overwritten in server.xml
#executortag="<Executor name=\\\"tomcatThreadPool\\\" namePrefix=\\\"catalina-exec-\\\" maxThreads=\\\"$MAXTHREADS\\\" minSpareThreads=\\\"10\\\" maxIdleTime=\\\"60000\\\" />"
#connectortag="<Connector executor=\\\"tomcatThreadPool\\\" port=\\\"$HTTPPORT\\\" connectionTimeout=\\\"20000\\\" redirectPort=\\\"8443\\\" />"
#enginetag="<Engine name=\\\"Catalina\\\" defaultHost=\\\"localhost\\\" jvmRoute=\\\"$JVMROUTE\\\">"
#
##Note that server.xml.original is created when the Tomcat is created
##This first sed program operates on server.xml.original and saves to .xml
##Operate on Connector tag, also add executor tag before it
#ssh -t -t $HOST "sed \"
#/<Connector port=\\\"8080\\\" protocol=\\\"HTTP\\\/1.1\\\"/, /\\\/>/ c\
#$executortag \
#$connectortag
#\" egg/$APPDIR/tomcat/conf/server.xml.original > egg/$APPDIR/tomcat/conf/server.xml"
#
##This sed command operates directly on server.xml
##Operate on Engine tag
#ssh -t -t $HOST "sed -i \"
#/<Engine name=\\\"Catalina\\\" defaultHost=\\\"localhost\\\">/ c\
#$enginetag
#\" egg/$APPDIR/tomcat/conf/server.xml"

