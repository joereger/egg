#!/bin/bash

source loginclude.sh

#Cron HOWTO
#sudo nano /etc/crontab (to create/remove jobs)
#sudo tail -f /var/log/cron (to view cron log)
#sudo crontab -e (to edit cronjobs)
#sudo /etc/init.d/crond restart (to restart daemon and load new/changed cronjobs)



if [ "${CRONNAME}" == "" ]; then
    echo "CRONNAME undefined, exiting"
    echo "CRONNAME undefined, exiting" >> $LOGFILEDEBUG
    exit
fi

if [ "${CRONLOCKTIMEOUTSECONDS}" == "" ]; then
    echo "CRONLOCKTIMEOUTSECONDS undefined, exiting"
    echo "CRONLOCKTIMEOUTSECONDS undefined, exiting" >> $LOGFILEDEBUG
    exit
fi

CRONLOCKSFILE=data/cron.locks

if [ ! -f "$CRONLOCKSFILE" ]; then
  echo "$CRONLOCKSFILE does not exist so creating it."
  echo "$CRONLOCKSFILE does not exist so creating it." >> $LOGFILEDEBUG
  cp data/cron.locks.sample $CRONLOCKSFILE
fi

./log.sh "CRON `date`: $CRONNAME"

while read cronpauseallline;
do

    #Ignore lines that start with a comment hash mark
    if [ $(echo "$cronpauseallline" | cut -c1) != "#" ]; then

        CRONNAME_A=$(echo "$cronpauseallline" | cut -d ":" -f1)
        RUNSTARTEDAT=$(echo "$cronpauseallline" | cut -d ":" -f2)

        if [ "$CRONNAME_A" == "$CRONNAME" ]; then
            #There is a lock... let's see if it's valid
            ./log.sh "Cron lock exists for $CRONNAME"
            #./log-status.sh "Cron lock exists for $CRONNAME"

            CURRENTTIME=`date +%s`
            echo CURRENTTIME=$CURRENTTIME
            RUNSTARTEDATPLUSTIMEOUT=$((RUNSTARTEDAT+CRONLOCKTIMEOUTSECONDS))
            echo RUNSTARTEDATPLUSTIMEOUT=$RUNSTARTEDATPLUSTIMEOUT

            if [ "${CURRENTTIME}" -lt "${RUNSTARTEDATPLUSTIMEOUT}"  ]; then
                ./log.sh "Cron lock for $CRONNAME, exiting"
                exit
            else
                ./log.sh "Cron lock for $CRONNAME has expired, continuing"
            fi

        fi
    fi
done < "$CRONLOCKSFILE"



CRONPAUSEALLFILE=data/cron.pause.all



while read cronpauseallline;
do

    #Ignore lines that start with a comment hash mark
    if [ $(echo "$cronpauseallline" | cut -c1) != "#" ]; then
        ./log.sh "Found a line in $CRONPAUSEALLFILE"
        CURRENTTIME=`date +%s`
        ./log.sh CURRENTTIME=$CURRENTTIME
        PAUSEENDSAT="$cronpauseallline"
        ./log.sh PAUSEENDSAT=$PAUSEENDSAT


        if [ "${PAUSEENDSAT}" -eq "0"  ]; then
            ./log.sh "Cron jobs paused indefinitely, exiting"
            exit
        fi

        if [ "${CURRENTTIME}" -lt "${PAUSEENDSAT}"  ]; then
            REMAININGSECONDS=$((PAUSEENDSAT-CURRENTTIME))
            REMAININGMINUTES=$((REMAININGSECONDS/60))
            ./log.sh "Cron jobs paused another $REMAININGMINUTES min, exiting"
            exit
        else
            ./log.sh "Cron pause has expired, continuing"
            rm -f $CRONPAUSEALLFILE
        fi


    fi
done < "$CRONPAUSEALLFILE"






#Delete any current line with this
sed -i "
/^${CRONNAME}:/ d\
" $CRONLOCKSFILE

#Write a lock record
CURRENTTIME=`date +%s`
sed -i "
/#BEGINDATA/ a\
$CRONNAME:$CURRENTTIME
" $CRONLOCKSFILE


