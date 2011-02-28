#!/bin/bash

source common.sh

echo "Reset all Tomcat start/stop locks? (y/n and hit enter)"



read YESORNO
if [ "$YESORNO" == "y" ]; then
    #Resetting is done by simply deleting score file
    rm -f data/tomcat.start.locks
    rm -f data/tomcat.stop.locks
    echo "Tomcat start/stop locks reset"
fi