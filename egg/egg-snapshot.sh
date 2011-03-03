#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: EBSVOLUME HOST(optional) DESCRIPTION(optional)"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a EBSVOLID"; exit; fi

EBSVOLUME=$1
TIMEPERIOD=$2
HOST=$3
DESCRIPTION=$4


./log.sh "Snapshot $EBSVOLUME start"

if [ "$HOST" != "" ]; then
    ./egg-mysql-stop.sh $HOST
    .log-debug.sh "Snapshot $EBSVOLUME freezing xfs filesystem"
    ssh -t -t $HOST "sudo xfs_freeze -f /vol"
fi


if [ "$DESCRIPTION" != "" ]; then
    DESCRIPTION="eggsnapshot"
else
    DESCRIPTION="eggsnapshot"$DESCRIPTION
fi
./log-debug.sh "Snapshot $EBSVOLUME Description=$DESCRIPTION"

export SNAPSHOTID=`${EC2_HOME}/bin/ec2-create-snapshot $EBSVOLUME -d $DESCRIPTION | grep SNAPSHOT | cut -f2`

if [ "$HOST" != "" ]; then
    .log-debug.sh "Snapshot $EBSVOLUME unfreezing xfs filesystem"
    ssh -t -t $HOST "sudo xfs_freeze -u /vol"
    ./egg-mysql-start.sh $HOST
fi

.log-debug.sh "Snapshot $EBSVOLUME adding tags"
${EC2_HOME}/bin/ec2-create-tags $SNAPSHOTID --tag eggsnapshot
if [ "$TIMEPERIOD" != "" ]; then
    ${EC2_HOME}/bin/ec2-create-tags $SNAPSHOTID --tag timeperiod=$TIMEPERIOD
fi

./log.sh "Snapshot $EBSVOLUME done"

