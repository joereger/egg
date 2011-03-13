#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE:"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

#Read APACHESFILE
exec 3<> $APACHESFILE; while read inapacheline <&3; do {
	if [ $(echo "$inapacheline" | cut -c1) != "#" ]; then
	
		APACHEID=$(echo "$inapacheline" | cut -d ":" -f1)

		./egg-apache-configure.sh $APACHEID


	fi
}; done; exec 3>&-
