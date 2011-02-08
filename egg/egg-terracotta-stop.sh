#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

ssh $HOST "export JAVA_HOME=/usr/lib/jvm/jre; terracotta-3.4.0_1/bin/stop-tc-server.sh"

