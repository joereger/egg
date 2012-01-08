#!/bin/bash

#echo "found conf/socketware/common.sh"

#Name of Amazon AWS Keyset to use
export KEYPAIR="socketware"

#Set up EC2 vars
export EC2_HOME=/home/ec2-user/.ec2/ec2-api-tools-1.5.2.3
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=/home/ec2-user/.ec2/pk-***REMOVED***.pem
export EC2_CERT=/home/ec2-user/.ec2/cert-***REMOVED***.pem
export PATH=/home/ec2-user/.ec2/ec2-api-tools-1.5.2.3/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/jre

#EC2 Name Tag for all instances
export EC2NAMETAG="eggcontrolled"

#Where to send email alerts
export EMAILALERTSTO="joe+eggsocketware@joereger.com"

