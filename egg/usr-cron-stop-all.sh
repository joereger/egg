#!/bin/bash

source common.sh


echo "Stop all cron jobs? (Type y/n and hit enter)"

CRONPAUSEALLFILE=data/cron.pause.all

read YESORNO
if [ "$YESORNO" == "y" ]; then
    #Pausing is done by creating a file with a timestamp in it.
    #The timestamp represents the time when cron jobs can start running again.
    rm -f $CRONPAUSEALLFILE
    echo "0" >> $CRONPAUSEALLFILE
    echo "Cron jobs stopped"
fi