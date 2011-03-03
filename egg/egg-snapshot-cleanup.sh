#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: EBSVOLUME TIMEPERIOD"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a EBSVOLUME"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a TIMEPERIOD"; exit; fi


EBSVOLUME=$1
TIMEPERIOD=$2

echo "Snapshot $TIMEPERIOD cleanup start"
./log-debug.sh "Snapshot $TIMEPERIOD cleanup start"


# How many snapshots to keep
keep=2


#SNAPSHOT    snap-12345678   vol-12345678    completed   2010-08-24T10:00:00+0000    100%    680505800880    1 DESCRIPTION
# get snapshot list. sort -k5 sorts on the 5th field (date). head -n -$keep
# returns all but the last $keep lines.
snaps=`${EC2_HOME}/bin/ec2-describe-snapshots -o self --filter volume-id=$EBSVOLUME --filter tag:Name=eggsnapshot --filter tag:timeperiod=$TIMEPERIOD | grep completed | grep "eggsnapshot" | sort -k5`

snap_status() {
    msg=$1
    shift
    echo `echo $@ | grep -o SNAPSHOT|wc -w` $msg
    echo $@ | sed "s/SNAPSHOT/\nSNAPSHOT/g;"
}

snap_status "$TIMEPERIOD snapshots:" $snaps

# cat, because echo eats newlines.
snaps_to_delete=`cat<<EOT | head -n -$keep
$snaps
EOT
`
snap_status "$TIMEPERIOD snapshots will be deleted:" $snaps_to_delete

snap_ids=`cat<<EOT | cut -f2
$snaps_to_delete
EOT`

for snap in $snap_ids
do
    echo "Deleting $TIMEPERIOD $snap"
    ./log-debug.sh "Deleting $TIMEPERIOD $snap"
    ${EC2_HOME}/bin/ec2-delete-snapshot $snap

done




echo "Snapshot $TIMEPERIOD cleanup done"
./log-debug.sh "Snapshot $TIMEPERIOD cleanup done"