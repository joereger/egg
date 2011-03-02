#!/bin/bash

#--------------------------
#Open cron job and create lock
CRONNAME="CRONINSTANCESSPEEDTEST"   #Only alphabetic, no spaces, no funky chars
CRONLOCKTIMEOUTSECONDS=300          #Not sure here
cd /home/ec2-user/egg
source cronincludetop.sh
#--------------------------

./egg-instances-speedtest.sh

#--------------------------
#Close and release lock
source cronincludebottom.sh
#--------------------------