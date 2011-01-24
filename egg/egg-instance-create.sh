#!/bin/bash

source common.sh

export amiid="ami-08728661"
#export config="/root/ec2/v1bundles/liverepeater-origin-lb.zip"
export key="joekey"
export id_file="/home/ec2-user/.ssh/joekey.pem"
export zone="us-east-1c"
export securitygroup1="default"
export securitygroup2="app"
export ip="1.2.3.4"

#if [ "$#" == "0" ]; then echo "!USAGE: INSTANCESIZE(optional) ELASTICIP(optional) Sizes: m1.small | m1.large | m1.xlarge | c1.medium | c1.xlarge | m2.xlarge | m2.2xlarge | m2.4xlarge | t1.micro"; exit; fi

INSTANCESIZE=$1
ELASTICIP=$2

if [ "$1" == "" ]; then INSTANCESIZE="t1.micro"; fi
echo Creating instance of size $INSTANCESIZE

# 	The variables that start with the name .EC2. are used by the Tools API. They are the directory where you downloaded your Tools installation and the key and cert files provided to you by Amazon when you created your instance. The other variables are used by the shell commands in this example, and include:
#
    #	* Amazon Image ID
    #	* Key name associated with this instance
    #	* The zone in which this instance was created
    #	* The group associated with this instance
    #	* The name of the user's EC2 identity file
    #	* The ESB volume ID
    #	* The mount directory within the EC2 instance
    #	* The device name to associate with the ESB volume when attached
    #	* The Elastic IP address to associate with the instance

#	Now it's time to start the instance, and then loop until it is running.

#
# Start the instance
# Capture the output so that
# we can grab the INSTANCE ID field
# and use it to determine when
# the instance is running
#
echo Launching AMI ${amiid}
${EC2_HOME}/bin/ec2-run-instances ${amiid} -t $INSTANCESIZE -k ${key} -g ${securitygroup1} -g ${securitygroup2} > /tmp/origin.ec2
if [ $? != 0 ]; then
   echo Error starting instance for image ${amiid}
   exit 1
fi
export iid=`cat /tmp/origin.ec2 | grep INSTANCE | cut -f2`

#echo ${iid} > /root/ec2/origin.iid

#
# Loop until the status changes to .running.
#
sleep 30
echo Starting instance ${iid}
export RUNNING="running"
export done="false"
while [ $done == "false" ]
do
   export status=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f6`
   if [ $status == ${RUNNING} ]; then
      export done="true"
   else
      echo Waiting...
      sleep 10
   fi
done
echo Instance ${iid} is running


#Add Tag(s)
ec2-create-tags ${iid} --tag Name="eggweb"
echo Tag added to Instance ${iid}


#	Now we have the running instance ID, which we will use going forward. We next attach the ESB volume to the running instance, associating a device name. After we attach the volume, we wait until its status indicates that it is attached.

#
# Attach the volume to the running instance
#
#	echo Attaching volume ${vol_name}
#	${EC2_HOME}/bin/ec2-attach-volume ${vol_name} -i ${iid} -d ${device_name}
#	sleep 15

#
# Loop until the volume status changes
# to "attached"
#
#	export ATTACHED="attached"
#	export done="false"
#	while [ $done == "false" ]
#	do
   #	export status=`${EC2_HOME}/bin/ec2-describe-volumes | grep ATTACHMENT | grep ${iid} | cut -f5`
   #	if [ $status == ${ATTACHED} ]; then
      #	export done="true"
   #	else
      #	echo Waiting...
      #	sleep 10
   #	fi
#	done
#	echo Volume ${vol_name} is attached
#	

#	Now we associate the Elastic IP address with the running instance. This capability is important in an environment where instances are being started and stopped at various points for scalability reasons, so these operations will happen with no interruption for the user.

#
# Associate the Elastic IP with the instance
# After this operation we just sleep a bit
#
if [ "$ELASTICIP" != "" ]; then  
	echo Associating elastic IP address $ELASTICIP
	${EC2_HOME}/bin/ec2-associate-address $ELASTICIP -i ${iid}
	sleep 30
fi


#Get the IP address
export ipaddress=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f18`
echo IP Address of ${iid} is ${ipaddress}


#Write a record to instances.conf
#TODO Properly form this record, choose internal instanceid, etc.
#echo "2:$INSTANCESIZE:${iid}:${ipaddress}:" >> conf/instances.conf




#	Our final step for starting our instance is to copy and execute some additional commands within the running instance. These operations will create a mount point and mount the volume. Our commands assume that any partitioning and file system type creation has already been setup in the Amazon image.s /etc/fstab file. We use SSH to copy and execute these commands. Because EC2 does not allow username/password authentication, we must provide our identity file to SSH.

#
# Start the operations within the instance
# Copy over the mount script and execute it
# The script setup_vol does:
#     mkdir /mnt/vol
#     mount /mnt./vol
#
#scp -i ${id_file} s3fs_setup.sh root@${ip}:/opt
#ssh -i ${id_file} root@${ip} . /opt/s3fs_setup.sh

#	Last, but not least, tell the user that we are ready to start using the running instance.

echo Image ${amiid} instance ${iid} is ready to go!
#echo ${iid} > current_instance