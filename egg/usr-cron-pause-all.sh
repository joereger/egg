#!/bin/bash

source common.sh


echo "Pause for how many minutes? (Type num and hit enter)"

CRONPAUSEALLFILE=data/cron.pause.all

read MINTOPAUSE
if [ "$MINTOPAUSE" != "" ]; then
    #Pausing is done by creating a file with a timestamp in it.
    #The timestamp represents the time when cron jobs can start running again.
    rm -f $CRONPAUSEALLFILE
    CURRENTTIME=`date +%s`
    LENGTHOFPAUSEINSECONDS=$((MINTOPAUSE*60))
    PAUSEENDSAT=$((CURRENTTIME+LENGTHOFPAUSEINSECONDS))
    #echo CURRENTTIME=$CURRENTTIME
    #echo PAUSEENDSAT=$PAUSEENDSAT
    #Write pause end time to cronpause file
    echo $PAUSEENDSAT >> $CRONPAUSEALLFILE
    echo "Cron jobs paused"
fi