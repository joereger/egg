#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: INSTANCEID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a INSTANCEID"; exit; fi

INSTANCEID=$1

${EC2_HOME}/bin/ec2-stop-instances $INSTANCEID
