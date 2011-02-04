#!/bin/bash

source common.sh

INSTANCESFILE=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$INSTANCESFILE" ]; then
  echo "Sorry, $INSTANCESFILE does not exist."
  exit 1
fi

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids-sample.conf $AMAZONIIDSFILE
fi

SOMETHINGHASCHANGED="0"
		
#Read INSTANCESFILE   
while read ininstancesline;
do
	#Ignore lines that start with a comment hash mark
	if [ $(echo "$ininstancesline" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID=$(echo "$ininstancesline" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$ininstancesline" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$ininstancesline" | cut -d ":" -f3)
		AMIID=$(echo "$ininstancesline" | cut -d ":" -f4)
		ELASTICIP=$(echo "$ininstancesline" | cut -d ":" -f5)
		EBSVOLUME=$(echo "$ininstancesline" | cut -d ":" -f6)
		EBSDEVICENAME=$(echo "$ininstancesline" | cut -d ":" -f7)
		
		#Default AMIID
		if [ "$AMIID" == "" ]; then
			AMIID="ami-08728661"
		fi
		
		#Read AMAZONIIDSFILE
		AMAZONINSTANCEID=""
		HOST=""
		while read amazoniidsline;
		do
			#Ignore lines that start with a comment hash mark
			if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
				LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
				if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
					AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
					HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
				fi
			fi
		done < "$AMAZONIIDSFILE"
		
		echo "   "
		echo Checking LOGICALINSTANCEID=$LOGICALINSTANCEID $INSTANCESIZE AMAZONINSTANCEID=$AMAZONINSTANCEID HOST=$HOST ELASTICIP=$ELASTICIP
		
		#Determine whether this instance is running
		thisinstanceisup=0
		export RUNNING="running"
		export status=`${EC2_HOME}/bin/ec2-describe-instances $AMAZONINSTANCEID | grep INSTANCE | cut -f6`
		if [ "$status" == "$RUNNING" ]; then
			export thisinstanceisup=1  	
		fi
		echo Thisinstanceisup=$thisinstanceisup
		
		#Start an instance if necessary
		if [ ${thisinstanceisup} == "0" ]; then
			echo "Will create amazon ec2 instance for logical instance $LOGICALINSTANCEID"
			
			#TEMP BLOCK OUT
			#if [ "1" == "0" ]; then
			
				
				export key="joekey"
				export id_file="/home/ec2-user/.ssh/joekey.pem"
				export zone="us-east-1c"
				export securitygroup1="default"
				export securitygroup2="$SECURITYGROUP"
				export ip="1.2.3.4"
				
				if [ "$INSTANCESIZE" == "" ]; then INSTANCESIZE="t1.micro"; fi

				./egg-log-status.sh "Launching AMI ${amiid} of size $INSTANCESIZE"
				${EC2_HOME}/bin/ec2-run-instances ${AMIID} -t $INSTANCESIZE -k ${key} -g ${securitygroup1} -g ${securitygroup2} > /tmp/origin.ec2
				if [ $? != 0 ]; then
				   ./egg-log-status.sh "Error starting instance for amazonimageid ${AMIID}"
				   exit 1
				fi
				export iid=`cat /tmp/origin.ec2 | grep INSTANCE | cut -f2`
	
				# Loop until the status changes to .running.
				sleep 30
				./egg-log-status.sh "Starting instance ${iid}"
				export RUNNING="running"
				export done="false"
				while [ $done == "false" ]
				do
				   export status=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f6`
				   if [ $status == ${RUNNING} ]; then
					  export done="true"
				   else
					  echo Waiting 10 sec...
					  sleep 10
				   fi
				done
				echo Instance ${iid} is running
				
				#Add Tag(s)
				ec2-create-tags ${iid} --tag Name="${EC2NAMETAG}"
				echo Tag added to Instance ${iid}


	
				# Associate the Elastic IP with the instance
				if [ "$ELASTICIP" != "" ]; then  
					./egg-log-status.sh "Associating elastic IP address $ELASTICIP"
					${EC2_HOME}/bin/ec2-associate-address $ELASTICIP -i ${iid}
					echo Waiting 30 seconds
					sleep 30
				fi
				
				#Get the IP address
				export ipaddress=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f18`
				./egg-log-status.sh "IP Address of ${iid} is ${ipaddress}"
			
				AMAZONINSTANCEID=${iid}
				HOST=${ipaddress}

				#Need to wait for SSH to be available
				export sshtest="yipee"
				export sshdone="false"
				while [ $sshdone == "false" ]
				do
				    export sshcheck=`ssh $HOST "[ -d ./ ] && echo yipee"`
					if [ "$sshcheck" == "$sshtest" ]; then
					    export sshdone="true"
					else
					    echo sshcheck=${sshcheck}
						echo "SSH not up yet, sleeping 10 seconds."
						sleep 10
					fi
				done
				./egg-log-status.sh "SSH is running"

				#Uninstall sendmail
				echo "Uninstalling sendmail"
				ssh -t -t $HOST "sudo yum -y remove sendmail"


				#Attach EBS volumes if necessary
				if [ "$EBSVOLUME" != "" ]; then
                    # Attach the volume to the running instance
                    # For future reference here's what I did to the volume to create the file system
                    # yum install xfsprogs
                    #grep -q xfs /proc/filesystems || sudo modprobe xfs
                    #sudo mkfs.xfs /dev/sdh
                    #Note that this filesystem creation is done manually and only once to make the EBS volume usable
                    ./egg-log-status.sh "Attaching volume ${EBSVOLUME}"
                    ${EC2_HOME}/bin/ec2-attach-volume ${EBSVOLUME} -i ${iid} -d ${EBSDEVICENAME}
                    echo "Sleeping 15 sec for volume to attach"
                    sleep 15
                    # Loop until the volume status changes to "attached"
                    export ATTACHED="attached"
                    export done="false"
                    while [ $done == "false" ]
                    do
                       export status=`${EC2_HOME}/bin/ec2-describe-volumes | grep ATTACHMENT | grep ${EBSVOLUME} | cut -f5`
                       if [ $status == ${ATTACHED} ]; then
                          export done="true"
                       else
                          echo "Waiting 10 secs"
                          sleep 10
                       fi
                    done
                    ./egg-log-status.sh "Volume ${EBSVOLUME} is attached"
                    #Configure the instance to have the drive on reboot and to have it mounted as /vol
                    ssh -t -t $HOST "echo '/dev/sdh /vol xfs noatime 0 0' | sudo tee -a /etc/fstab"
                    ssh -t -t $HOST "sudo mkdir -m 000 /vol"
                    ssh -t -t $HOST "sudo mount /vol"
				fi
			
			#TEMP BLOCK OUT
			#fi
			
			#Delete any current line with this logicalinstanceid
			sed -i "
			/^${LOGICALINSTANCEID}:/ d\
			" $AMAZONIIDSFILE
			
			#Write a record to amazoniids.conf
			sed -i "
			/#BEGINDATA/ a\
			$LOGICALINSTANCEID:$AMAZONINSTANCEID:$HOST
			" $AMAZONIIDSFILE
			
			#Any time we change instances we have to update the apacheconfig
			SOMETHINGHASCHANGED="1"
		fi
	fi
done < "$INSTANCESFILE"

#Any time we change instances we have to update the apacheconfig
if [ "$SOMETHINGHASCHANGED" == "1" ]; then
    ./egg-apaches-verify-up.sh
	./egg-apaches-configure-all.sh
fi



			
