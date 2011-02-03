#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST APPDIR"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an APPDIR"; exit; fi

HOST=$1
APPDIR=$2

ssh -t -t $HOST "sudo chmod -R 755 /home/ec2-user/egg/$APPDIR"
ssh -t -t $HOST "cd egg/$APPDIR/tomcat/bin/; chmod 777 *.sh;"
ssh -t -t $HOST "export CATALINA_HOME=/home/ec2-user/egg/$APPDIR/tomcat; export JRE_HOME=$JAVA_HOME; bash egg/$APPDIR/tomcat/bin/catalina.sh start"