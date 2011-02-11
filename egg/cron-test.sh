#!/bin/bash

#--------------------------
#Open cron job and create lock
CRONNAME="CRONTEST"  #Only alphabetic, no spaces, no funky chars
CRONLOCKTIMEOUTSECONDS=120   #Make this longer than you ever expect this cron job to take to run
cd /home/ec2-user/egg
source cronincludetop.sh
#--------------------------

echo "cron-test.sh"
echo "sleeping for 180 seconds"
sleep 180
echo "done sleeping for 180 seconds"

#--------------------------
#Close and release lock
source cronincludebottom.sh
#--------------------------