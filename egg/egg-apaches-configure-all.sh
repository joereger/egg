#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE:"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

APACHESFILE=conf/apaches.conf

if [ ! -f "$APACHESFILE" ];
then
  echo "Sorry, $APACHESFILE does not exist."
  exit 1
fi


#Read APACHESFILE
while read inapachesline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$inapachesline" | cut -c1) != "#" ]; then
	
		APACHEID=$(echo "$inapachesline" | cut -d ":" -f1)
		
		./egg-apache-configure.sh $APACHEID

	fi
done < "$APACHESFILE"
