#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

./log-status.sh "Starting MONGODB on $HOST"
ssh -t -t $HOST "./mongodb-linux-x86_64-2.0.4/bin/mongod --fork --journal --logpath /vol/mongodblog/mongod.log --dbpath /vol/mongodbdata/"



