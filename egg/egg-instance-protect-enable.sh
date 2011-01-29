#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: AMAZONINSTANCEID"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a AMAZONINSTANCEID"; exit; fi

AMAZONINSTANCEID=$1

#http://alestic.com/2010/01/ec2-instance-locking

${EC2_HOME}/bin/ec2-modify-instance-attribute --disable-api-termination true ${AMAZONINSTANCEID}
#${EC2_HOME}/bin/ec2-modify-instance-attribute --instance-initiated-shutdown-behavior stop ${AMAZONINSTANCEID}
${EC2_HOME}/bin/ec2-modify-instance-attribute --block-device-mapping /dev/sda1=::false ${AMAZONINSTANCEID}
#${EC2_HOME}/bin/ec2-modify-instance-attribute --block-device-mapping /dev/sdh=::false ${AMAZONINSTANCEID}