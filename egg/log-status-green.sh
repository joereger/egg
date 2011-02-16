#!/bin/bash

source colors.sh
source loginclude.sh

if [ "$#" == "0" ]; then echo "!USAGE: WHATTOLOG"; exit; fi
if [ "$1" == "" ]; then echo "Must provide WHATTOLOG"; exit; fi

WHATTOLOG=$1

#echo -e ${cf_green}$WHATTOLOG${c_reset}
echo -e ${cf_green}$WHATTOLOG${c_reset} >> $LOGFILEDEBUG
echo -e ${cf_green}$WHATTOLOG${c_reset} >> $LOGFILEINFO
echo -e ${cf_green}$WHATTOLOG${c_reset} >> $LOGFILESTATUS

