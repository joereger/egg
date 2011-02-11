#!/bin/bash

#--------------------------
#Open and lock the cron job
CRONNAME=$0
CRONLOCKTIMEOUTSECONDS=120
cd /home/ec2-user/egg
source cronincludetop.sh
#--------------------------

echo "middle of cron-test.sh"

#--------------------------
#Close the cron job
source cronincludebottom.sh
#--------------------------
