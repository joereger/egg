#!/bin/bash

#--------------------------
#Open cron job and create lock
CRONNAME="CRONCHECK"          #Only alphabetic, no spaces, no funky chars
CRONLOCKTIMEOUTSECONDS=2000   #Not sure here
cd /home/ec2-user/egg
source cronincludetop.sh
#--------------------------

./egg-tomcats-check-all.sh

#--------------------------
#Close and release lock
source cronincludebottom.sh
#--------------------------