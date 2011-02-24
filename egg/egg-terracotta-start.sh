#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST TERRACOTTAID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a TERRACOTTAID"; exit; fi

HOST=$1
TERRACOTTAID=$2

./log-status.sh "Starting Terracotta$TERRACOTTAID on $HOST"


#Send the latest startup script
STARTUPSCRIPTTOUSE=conf/terracotta/default.start-tc-server.sh
if [ -e conf/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh ]; then
	./log.sh "conf/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh exists"
    STARTUPSCRIPTTOUSE=conf/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh
else
	./log.sh "conf/terracotta/terracottaid$TERRACOTTAID.start-tc-server.sh not found, using default"
fi
ssh -t -t $HOST "mkdir -p terracotta-3.4.0_1/bin"
scp $STARTUPSCRIPTTOUSE ec2-user@$HOST:start-tc-server.sh
ssh -t -t $HOST "cp start-tc-server.sh terracotta-3.4.0_1/bin/start-tc-server.sh"
ssh -t -t $HOST "sudo chmod 755 terracotta-3.4.0_1/bin/start-tc-server.sh"
ssh -t -t $HOST "rm start-tc-server.sh"

#Send the latest config file
#@TODO Some day will need to parse this config file to place hostnames in it... once terracotta goes multi-machine
CONFTOUSE=conf/terracotta/default.tc-config.xml
if [ -e conf/terracotta/terracottaid$TERRACOTTAID.tc-config.xml ]; then
	./log.sh "conf/terracotta/terracottaid$TERRACOTTAID.tc-config.xml exists"
    CONFTOUSE=conf/terracotta/terracottaid$TERRACOTTAID.tc-config.xml
else
	./log.sh "conf/terracotta/terracottaid$TERRACOTTAID.tc-config.xml not found, using default"
fi
ssh -t -t $HOST "mkdir -p terracotta-3.4.0_1"
scp $CONFTOUSE ec2-user@$HOST:tc-config.xml
ssh -t -t $HOST "cp tc-config.xml terracotta-3.4.0_1/tc-config.xml"
ssh -t -t $HOST "sudo chmod 755 terracotta-3.4.0_1/tc-config.xml"
ssh -t -t $HOST "rm tc-config.xml"


#Get on with the business of actually starting the server
ssh $HOST "export JAVA_HOME=/usr/lib/jvm/jre; nohup terracotta-3.4.0_1/bin/start-tc-server.sh -f /home/ec2-user/terracotta-3.4.0_1/tc-config.xml > terracotta/backgroundprocess.log 2>&1 & "
./log-status-green.sh "Terracotta started on $HOST"
