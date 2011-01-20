#!/bin/bash

#Set up EC2 vars
export EC2_HOME=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=/home/ec2-user/.ec2/pk-***REMOVED***.pem
export EC2_CERT=/home/ec2-user/.ec2/cert-***REMOVED***.pem
export PATH=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/jre

export amiid="ami-08728661"
#export config="/root/ec2/v1bundles/liverepeater-origin-lb.zip"
export key="joekey"
export id_file="/home/ec2-user/.ssh/joekey.pem"
export zone="us-east-1c"
export group="app,default"
export ip="1.2.3.4"


if [ "$#" == "0" ]; then echo "!USAGE: INSTANCEID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a INSTANCEID"; exit; fi

./common.sh

INSTANCEID=$1

${EC2_HOME}/bin/ec2-start-instances $INSTANCEID