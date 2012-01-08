#!/bin/bash

#Name of Amazon AWS Keyset to use
export KEYPAIR="joekey"

#Set up EC2 vars
export EC2_HOME=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=/home/ec2-user/.ec2/pk-***REMOVED***.pem
export EC2_CERT=/home/ec2-user/.ec2/cert-***REMOVED***.pem
export PATH=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/jre

#EC2 Name Tag for all instances
export EC2NAMETAG="eggpuppet"

#Where to send email alerts
export EMAILALERTSTO="joe+egg@joereger.com"