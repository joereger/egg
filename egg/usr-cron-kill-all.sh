#!/bin/bash

source common.sh


echo "Kill all cron processes? (Type y/n and hit enter)"

read YESORNO
if [ "$YESORNO" == "y" ]; then

    echo "Cron process shutdown starting"
    export prockilled="false"
    while [ $prockilled == "false" ]; do
        PID=`ps -ef | grep egg | grep -v grep | grep -v cron-kill | awk '{print $2}' | head -n1 `
        if [ "$PID" != "" ]; then
            echo "Killing PID=$PID"
            kill -9 $PID
        else
            echo "PID empty so leaving loop"
            prockilled="true"
        fi
        #sleep 2  #To prevent a CPU-hogging loop
    done


    echo "Cron jobs stopped"
fi