#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

ssh -t -t $HOST "mkdir -p terracotta-3.4.0_1"
scp conf/terracotta/default.tc-config.xml ec2-user@$HOST:tc-config.xml
ssh -t -t $HOST "cp tc-config.xml terracotta-3.4.0_1/tc-config.xml"










