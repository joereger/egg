#!/bin/bash

source common.sh


echo "Start all cron jobs? (Type y/n and hit enter)"

read YESORNO
if [ "$YESORNO" == "y" ]; then
    #Pausing is done by creating a file with a timestamp in it.
    #The timestamp represents the time when cron jobs can start running again.
    rm -f data/tomcat.stop.locks
    rm -f data/tomcat.start.locks
    rm -f data/tomcat.stop.locks
    rm -f data/cron.pause.all
    echo "Cron jobs started"
fi