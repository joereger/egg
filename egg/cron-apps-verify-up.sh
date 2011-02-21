#!/bin/bash

#--------------------------
#Open cron job and create lock
CRONNAME="CRONVERIFYUP"          #Only alphabetic, no spaces, no funky chars
CRONLOCKTIMEOUTSECONDS=3600   #One hour... this could be a long running job
cd /home/ec2-user/egg
source cronincludetop.sh
#--------------------------

./egg-apps-verify-up.sh

#--------------------------
#Close and release lock
source cronincludebottom.sh
#--------------------------