#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1


./egg-instances-verify-up.sh
./egg-mysqls-verify-up.sh
./egg-terracottas-verify-up.sh
./egg-apaches-verify-up.sh
./egg-tomcats-verify-up.sh
./egg-tomcats-check-all.sh


