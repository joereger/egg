#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: SUBJECT MESSAGE"; exit; fi
if [ "$1" == "" ]; then echo "Must provide an SUBJECT"; exit; fi
if [ "$2" == "" ]; then echo "Must provide a MESSAGE"; exit; fi

TO="joe+egg@joereger.com"
SUBJECT=$1
MESSAGE=$2
CURRENTTIME=`TZ=EST date +"%b %d %r %N"`

echo "[$CURRENTTIME] $SUBJECT" >> logs/mail.log
echo $MESSAGE | mail -s "$SUBJECT  [$CURRENTTIME]" "$TO"



