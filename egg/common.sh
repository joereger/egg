#!/bin/bash

source colors.sh
source loginclude.sh

#Redirect stdout to LOGFILEDEBUG
#$DONTREDITSTDOUTTOLOGFILE allows me to turn this off for certain scripts
if [ "$DONTREDITSTDOUTTOLOGFILE" == "" ]; then
    exec > >(tee -a $LOGFILEDEBUG)
    exec 2>&1
fi

#Log script execution yo yo yo
#echo -e ${cc_black_cyan}
WHATTOLOG="$0 $@"
echo -e ${cc_black_cyan}`TZ=EST date +"%b%d"`" "`TZ=EST date +"%r"`" "$WHATTOLOG${c_reset} >> $LOGFILEDEBUG
echo -e ${cc_black_cyan}`TZ=EST date +"%b%d"`" "`TZ=EST date +"%r"`" "$WHATTOLOG${c_reset} >> $LOGFILEINFO
#./log-status-green.sh "$0 $@"
#echo -e ${c_reset}

#Set up EC2 vars
export EC2_HOME=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=/home/ec2-user/.ec2/pk-***REMOVED***.pem
export EC2_CERT=/home/ec2-user/.ec2/cert-***REMOVED***.pem
export PATH=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/jre

#EC2 Name Tag for all instances
export EC2NAMETAG="eggpuppet"

