#!/bin/bash

#--------------------------
#Open cron job and create lock
CRONNAME="CRONSNAPSHOTSWEEKLY"          #Only alphabetic, no spaces, no funky chars
CRONLOCKTIMEOUTSECONDS=3600   #This could be a long running job
cd /home/ec2-user/egg
source cronincludetop.sh
#--------------------------

./egg-snapshots-create.sh weekly

#--------------------------
#Close and release lock
source cronincludebottom.sh
#--------------------------