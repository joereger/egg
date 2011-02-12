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

#I can put tomcatid23.server.xml into /conf/apps/$APPNAME/ to override default base server.xml
SERVERXMLTOUSE=conf/tomcat/default.server.xml
if [ -e conf/apps/$APP/tomcatid$TOMCATID.server.xml ]; then
	echo "conf/apps/$APP/tomcatid$TOMCATID.server.xml exists"
    SERVERXMLTOUSE=conf/apps/$APP/tomcatid$TOMCATID.server.xml
else
	echo "conf/apps/$APP/tomcatid$TOMCATID.server.xml not found, using default server.xml"
fi

#Make a copy of the base file to use
cp $SERVERXMLTOUSE data/tomcatid$TOMCATID.server.xml.tmp

#Replace key elements
sed -i "s/\[MAXTHREADS\]/$MAXTHREADS/g" data/tomcatid$TOMCATID.server.xml.tmp
sed -i "s/\[HTTPPORT\]/$HTTPPORT/g" data/tomcatid$TOMCATID.server.xml.tmp
sed -i "s/\[JVMROUTE\]/$JVMROUTE/g" data/tomcatid$TOMCATID.server.xml.tmp

#Transfer to egg/$APPDIR/tomcat/conf/server.xml on $HOST
scp data/tomcatid$TOMCATID.server.xml.tmp ec2-user@$HOST:server.xml
ssh -t -t $HOST "sudo cp server.xml egg/$APPDIR/tomcat/conf/server.xml"
ssh -t -t $HOST "rm -f server.xml"


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

