#!/bin/bash

source colors.sh

if [ "$#" == "0" ]; then echo "!USAGE: WHATTOLOG"; exit; fi
if [ "$1" == "" ]; then echo "Must provide WHATTOLOG"; exit; fi

WHATTOLOG=$1

#echo `date`" - "$WHATTOLOG >> /home/ec2-user/egg/logs/debug.log
#echo -e ${cf_green}
#echo `date +"%b%d"`" "`date +"%r"`" "$WHATTOLOG >> /home/ec2-user/egg/logs/debug.log
echo -e ${cf_green}$WHATTOLOG${c_reset} >> /home/ec2-user/egg/logs/debug.log
echo -e ${cf_green}$WHATTOLOG${c_reset} >> /home/ec2-user/egg/logs/status.log
#echo -e ${c_reset}
