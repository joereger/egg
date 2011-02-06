#!/bin/bash

source common.sh

if [ "$#" == "0" ]; then echo "!USAGE: HOST"; exit; fi
if [ "$1" == "" ]; then echo "Must provide a HOST"; exit; fi

HOST=$1

scp resources/terracotta-3.4.0_1.tar.gz ec2-user@$HOST:terracotta-3.4.0_1.tar.gz
ssh -t -t $HOST "tar xvzf terracotta-3.4.0_1.tar.gz"
ssh -t -t $HOST "rm -f terracotta-3.4.0_1.tar.gz"










