#!/bin/bash

source common.sh

#if [ "$#" == "0" ]; then echo "!USAGE: APP"; exit; fi
#if [ "$1" == "" ]; then echo "Must provide an APP"; exit; fi

#APP=$1

#Start time counter
VSTARTTIME=`date +%s`

./pulse-update.sh "VerifyUp" "OK ./egg-instances-verify-up.sh"
./egg-instances-verify-up.sh

./pulse-update.sh "VerifyUp" "OK ./egg-mysqls-verify-up.sh"
./egg-mysqls-verify-up.sh

./pulse-update.sh "VerifyUp" "OK ./egg-terracottas-verify-up.sh"
./egg-terracottas-verify-up.sh

./pulse-update.sh "VerifyUp" "OK ./egg-apaches-verify-up.sh"
./egg-apaches-verify-up.sh

./pulse-update.sh "VerifyUp" "OK ./egg-tomcats-verify-up.sh"
./egg-tomcats-verify-up.sh

#CURRENTTIME=echo `TZ=EST date +"%r"`
#./pulse-update.sh "VerifyUp" "OK ./egg-tomcats-check-all.sh ${CURRENTTIME}"
#./egg-tomcats-check-all.sh

#Start time counter
VENDTIME=`date +%s`
VEXECUTIONTIMEINSECONDS=$((VENDTIME-VSTARTTIME))


./pulse-update.sh "VerifyUp" "OK DONE ${VEXECUTIONTIMEINSECONDS}s"
./log.sh "egg-verify-up.sh DONE ${VEXECUTIONTIMEINSECONDS}s"

