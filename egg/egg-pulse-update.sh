#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: KEY VALUE"; exit; fi
if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi
if [ "$2" == "" ]; then echo "Must provide an VALUE"; exit; fi

KEY=$1
VALUE=$2

#Delete any current line with this logicalinstanceid
sed -i "
/^${KEY}:/ d\
" $PULSEFILE

#Write a record to amazoniids.conf
sed -i "
/#BEGINDATA/ a\
$KEY:$VALUE
" $PULSEFILE





