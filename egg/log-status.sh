#!/bin/bash

source colors.sh
source loginclude.sh

if [ "$#" == "0" ]; then echo "!USAGE: WHATTOLOG"; exit; fi
if [ "$1" == "" ]; then echo "Must provide WHATTOLOG"; exit; fi

WHATTOLOG=$1

#echo -e $WHATTOLOG
echo -e $WHATTOLOG >> $LOGFILEDEBUG
echo -e $WHATTOLOG >> $LOGFILEINFO
echo -e $WHATTOLOG >> $LOGFILESTATUS

