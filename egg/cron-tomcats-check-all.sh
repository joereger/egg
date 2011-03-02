#!/bin/bash

sleep 10 #done because i want to be able to lock this out if verify-up runs at same time

#--------------------------
#Open cron job and create lock
CRONNAME="CRONCHECK"          #Only alphabetic, no spaces, no funky chars
CRONLOCKTIMEOUTSECONDS=3600   #Not sure here
cd /home/ec2-user/egg
source cronincludetop.sh
#--------------------------

./egg-tomcats-check-all.sh

#--------------------------
#Close and release lock
source cronincludebottom.sh
#--------------------------