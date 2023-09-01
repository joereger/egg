#!/bin/bash

#echo "found conf/socketware/common.sh"

#Name of Amazon AWS Keyset to use
export KEYPAIR="socketware"

#Set up EC2 vars
export EC2_HOME=/home/ec2-user/.ec2/ec2-api-tools-1.5.2.3
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=/home/ec2-user/.ec2/pk-N4RSXHVO275F2E3XII4SHC6RN2DZ7KV4.pem
export EC2_CERT=/home/ec2-user/.ec2/cert-N4RSXHVO275F2E3XII4SHC6RN2DZ7KV4.pem
export PATH=/home/ec2-user/.ec2/ec2-api-tools-1.5.2.3/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/jre

#EC2 Name Tag for all instances
export EC2NAMETAG="eggcontrolled"

#Where to send email alerts
export EMAILALERTSTO="joe+eggsocketware@joereger.com"

