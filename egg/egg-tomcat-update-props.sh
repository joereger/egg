#!/bin/bash

source common.sh

if [ "$#" -eq "0" ]; then echo "!USAGE: HOST APP APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APP"; exit; fi
if [ "$3" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APP=$2
APPDIR=$3

./egg-log.sh "HOST is $HOST"
./egg-log.sh "APP is $APP"
./egg-log.sh "APPDIR is $APPDIR"

#Delete combined.props, in case it exists and then create the output/combined file
if [ -e conf/$APP/combined.props ]; then
	rm conf/$APP/combined.props
fi
mkdir -p "conf/$APP"
touch "conf/$APP/combined.props"

#Determine which of system.props and/or instance.props exist and combine them into combined.props
if [ -e conf/$APP/system.props ] && [ -e conf/$APP/$APPDIR/instance.props ]; then
	./egg-log.sh "Both system.props and instance.props exist"
	cat conf/$APP/system.props >> conf/$APP/combined.props
	echo -e "\n" >> conf/$APP/combined.props
	cat conf/$APP/$APPDIR/instance.props >> conf/$APP/combined.props
elif [ -e conf/$APP/system.props ]; then
	./egg-log.sh "Only system.props exists"
	cp conf/$APP/system.props conf/$APP/combined.props
elif [ -e conf/$APP/$APPDIR/instance.props ]; then
	./egg-log.sh "Only instance.props exists"
	cp conf/$APP/$APPDIR/instance.props conf/$APP/combined.props
else
	./egg-log.sh "Neither instance.props nor system.props exist"
fi

#Make sure /conf exists
ssh $HOST "mkdir -p egg/$APPDIR/tomcat/webapps/ROOT/conf"

#Copy combined.props to instance.props on remote Tomcat
scp conf/$APP/combined.props ec2-user@$HOST:~/egg/$APPDIR/tomcat/webapps/ROOT/conf/instance.props

#Delete combined.props
rm conf/$APP/combined.props
