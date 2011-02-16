#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

./log-status.sh "Starting Terracotta on $HOST"
ssh $HOST "export JAVA_HOME=/usr/lib/jvm/jre; nohup terracotta-3.4.0_1/bin/start-tc-server.sh -f /home/ec2-user/terracotta-3.4.0_1/tc-config.xml > terracotta/backgroundprocess.log 2>&1 & "
./log-status-green.sh "Terracotta started on $HOST"
