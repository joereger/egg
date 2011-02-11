#!/bin/bash



if [ "${CRONNAME}" == "" ]; then
    echo "CRONNAME undefined, exiting"
    echo "CRONNAME undefined, exiting" >> /home/ec2-user/egg/logs/debug.log
    exit
fi

if [ "${CRONLOCKTIMEOUTSECONDS}" == "" ]; then
    echo "CRONLOCKTIMEOUTSECONDS undefined, exiting"
    echo "CRONLOCKTIMEOUTSECONDS undefined, exiting" >> /home/ec2-user/egg/logs/debug.log
    exit
fi

CRONLOCKSFILE=data/cron.locks

if [ ! -f "$CRONLOCKSFILE" ]; then
  echo "$CRONLOCKSFILE does not exist so creating it."
  echo "$CRONLOCKSFILE does not exist so creating it." >> /home/ec2-user/egg/logs/debug.log
  cp data/cron.locks.sample $CRONLOCKSFILE
fi

./egg-log-status.sh "Cron `date`: $0"

while read cronlockline;
do

    #Ignore lines that start with a comment hash mark
    if [ $(echo "$cronlockline" | cut -c1) != "#" ]; then

        CRONNAME_A=$(echo "$cronlockline" | cut -d ":" -f1)
        RUNSTARTEDAT=$(echo "$cronlockline" | cut -d ":" -f2)

        if [ "$CRONNAME_A" == "$CRONNAME" ]; then
            #There is a lock... let's see if it's valid
            echo "Cron lock exists for $CRONNAME"
            ./egg-log-status.sh "Cron lock exists for $CRONNAME"

            CURRENTTIME=`date +%s`
            CURRENTTIMEPLUSTIMEOUT=$CURRENTTIME+$CRONLOCKTIMEOUTSECONDS



        fi
    fi
done < "$CRONLOCKSFILE"




#
##Delete any current line with this logicalinstanceid
#sed -i "
#/^${CRONNAME}:/ d\
#" $CRONLOCKSFILE
#
##Write a record to amazoniids.conf
#sed -i "
#/#BEGINDATA/ a\
#$LOGICALINSTANCEID:$AMAZONINSTANCEID:$HOST:$INTERNALHOSTNAME
#" $CRONLOCKSFILE


