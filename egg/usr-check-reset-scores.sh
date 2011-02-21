#!/bin/bash

source common.sh

echo "Start all Check scores? (Type y/n and hit enter)"

CHECKTOMCATSFILE=data/check.tomcats

read YESORNO
if [ "$YESORNO" == "y" ]; then
    #Resetting is done by simply deleting score file
    rm -f $CHECKTOMCATSFILE
    echo "Check scores reset"
fi