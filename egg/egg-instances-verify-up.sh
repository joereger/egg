#!/bin/bash

source common.sh

INSTANCESFILEIVU=conf/instances.conf
AMAZONIIDSFILE=data/amazoniids.conf

if [ ! -f "$INSTANCESFILEIVU" ]; then
  echo "Sorry, $INSTANCESFILEIVU does not exist."
  exit 1
fi

if [ ! -f "$AMAZONIIDSFILE" ]; then
  echo "$AMAZONIIDSFILE does not exist so creating it."
  cp data/amazoniids.conf.sample $AMAZONIIDSFILE
fi

SOMETHINGHASCHANGED="0"
ALLISWELL=1
		
#Read INSTANCESFILE   
while read line_instances_ivu;
do

	#Ignore lines that start with a comment hash mark
	if [ $(echo "$line_instances_ivu" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID=$(echo "$line_instances_ivu" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$line_instances_ivu" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$line_instances_ivu" | cut -d ":" -f3)
		AMIID=$(echo "$line_instances_ivu" | cut -d ":" -f4)
		ELASTICIP=$(echo "$line_instances_ivu" | cut -d ":" -f5)
		EBSVOLUME=$(echo "$line_instances_ivu" | cut -d ":" -f6)
		EBSDEVICENAME=$(echo "$line_instances_ivu" | cut -d ":" -f7)
		
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
		
		echo " "
		./log-blue.sh "LOGICALINSTANCEID=$LOGICALINSTANCEID $INSTANCESIZE IID=$AMAZONINSTANCEID HOST=$HOST ELASTICIP=${ELASTICIP}"
		
		#Determine whether this instance is running
		thisinstanceisup=0
		export RUNNING="running"
		export status=`${EC2_HOME}/bin/ec2-describe-instances $AMAZONINSTANCEID | grep INSTANCE | cut -f6`
		if [ "$status" == "$RUNNING" ]; then
			export thisinstanceisup=1  	
		fi
		./log.sh "Thisinstanceisup=$thisinstanceisup"
		
		#Start an instance if necessary
		if [ "${thisinstanceisup}" == "0" ]; then
		    ALLISWELL=0
			./log-status-red.sh "Instance $LOGICALINSTANCEID not found, will create"

            export key="joekey"
            export id_file="/home/ec2-user/.ssh/joekey.pem"
            export zone="us-east-1c"
            export securitygroup1="default"
            export securitygroup2="$SECURITYGROUP"
            export ip="1.2.3.4"

            if [ "$INSTANCESIZE" == "" ]; then
                INSTANCESIZE="t1.micro"
            fi

            ./log-status-green.sh "Creating $INSTANCESIZE instance from AMI ${AMIID} "
#            ${EC2_HOME}/bin/ec2-run-instances ${AMIID} -t $INSTANCESIZE -z ${zone} -k ${key} -g ${securitygroup1} -g ${securitygroup2} > /tmp/origin.ec2
#            if [ $? != 0 ]; then
#               ./log-status-green.sh "Error starting instance for amazonimageid ${AMIID}"
#               continue
#            fi
#            export iid=`cat /tmp/origin.ec2 | grep INSTANCE | cut -f2`
            export iid=`${EC2_HOME}/bin/ec2-run-instances ${AMIID} -t $INSTANCESIZE -z ${zone} -k ${key} -g ${securitygroup1} -g ${securitygroup2} | grep INSTANCE | cut -f2`
            if [ $? != 0 ]; then
               ./log-status-green.sh "Error starting instance for amazonimageid ${AMIID}"
               continue
            fi
            ./log.sh "Amazon iid=$iid created, waiting for it to be RUNNING"

            # Loop until the status changes to .running.
            export RUNNING="running"
            export done="false"
            while [ $done == "false" ]
            do
               export status=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f6`
               if [ $status == ${RUNNING} ]; then
                  export done="true"
               else
                  ./log.sh "Sleeping 10 seconds for instance to be RUNNING"
                  sleep 10
               fi
            done
            ./log.sh "Instance ${iid} is RUNNING"

            #Add Tag(s)
            ./log.sh "Starting to add tag"
            ec2-create-tags ${iid} --tag Name="${EC2NAMETAG}"
            ./log.sh "Tag ${EC2NAMETAG} added to Instance ${iid}"

            # Associate the Elastic IP with the instance
            if [ "$ELASTICIP" != "" ]; then
                ./log.sh "Associating elastic IP address $ELASTICIP"
                ${EC2_HOME}/bin/ec2-associate-address $ELASTICIP -i ${iid}
                ./log.sh "Waiting 30 seconds for elasticip to be assigned"
                sleep 30
            fi

            #Get the IP address
            export ipaddress=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f18`
            ./log.sh "Internal IP Address of ${iid} is ${ipaddress}"

            #Get the internalhost address
            export INTERNALHOSTNAME=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f5`
            ./log.sh "Internal Host of ${iid} is ${INTERNALHOSTNAME}"

            AMAZONINSTANCEID=${iid}
            HOST=${ipaddress}

            #Need to wait for SSH to be available
            export sshtest="yipee"
            export sshdone="false"
            while [ $sshdone == "false" ]
            do
                export sshcheck=`</dev/null ssh $HOST "[ -d ./ ] && echo yipee"`
                if [ "$sshcheck" == "$sshtest" ]; then
                    export sshdone="true"
                else
                    ./log.sh "SSH not up yet, sleeping 10 seconds."
                    sleep 10
                fi
            done
            ./log.sh "SSH is running"

            #Uninstall sendmail
            ./log.sh "Uninstalling sendmail"
            sendmailuninstall=`</dev/null ssh -n -t -t $HOST "sudo yum -y remove sendmail"`
            #echo $sendmailuninstall
            ./log.sh "Done uninstalling sendmail"

            #Remap port 25 to port 8025 so that Java can bind to it when running as non-root user
            iptablesremap=`</dev/null ssh -n -t -t $HOST "sudo iptables -t nat -A PREROUTING -p tcp --dport 25 -j REDIRECT --to-port 8025"`
            ./log.sh "Done remapping port 25 to post 8025"

            #Attach EBS volumes if necessary
            if [ "$EBSVOLUME" != "" ]; then
                # Attach the volume to the running instance
                # For future reference here's what I did to the volume to create the file system
                # yum install xfsprogs
                #grep -q xfs /proc/filesystems || sudo modprobe xfs
                #sudo mkfs.xfs /dev/sdh
                #Note that this filesystem creation is done manually and only once to make the EBS volume usable
                ./log.sh "Attaching volume ${EBSVOLUME}"
                ${EC2_HOME}/bin/ec2-attach-volume ${EBSVOLUME} -i ${iid} -d ${EBSDEVICENAME}
                ./log.sh "Sleeping 10 sec for volume to attach"
                sleep 10
                # Loop until the volume status changes to "attached"
                export ATTACHED="attached"
                export done="false"
                while [ $done == "false" ]
                do
                   export status=`${EC2_HOME}/bin/ec2-describe-volumes | grep ATTACHMENT | grep ${EBSVOLUME} | cut -f5`
                   if [ "$status" == "${ATTACHED}" ]; then
                      export done="true"
                   else
                      ./log.sh "Sleeping 10 sec for volume to attach"
                      sleep 10
                   fi
                done
                ./log.sh "Volume ${EBSVOLUME} is attached"
                #Configure the instance to have the drive on reboot and to have it mounted as /vol
                sshtmp1=`</dev/null ssh -t -t $HOST "echo '/dev/sdh /vol xfs noatime 0 0' | sudo tee -a /etc/fstab"`
                echo $sshtmp1
                sshtmp2=`</dev/null ssh -t -t $HOST "sudo mkdir -m 000 /vol"`
                echo $sshtmp2
                sshtmp3=`</dev/null ssh -t -t $HOST "sudo mount /vol"`
                echo $sshtmp3
            fi

			
			#Delete any current line with this logicalinstanceid
			sed -i "
			/^${LOGICALINSTANCEID}:/ d\
			" $AMAZONIIDSFILE
			
			#Write a record to amazoniids.conf
			sed -i "
			/#BEGINDATA/ a\
			$LOGICALINSTANCEID:$AMAZONINSTANCEID:$HOST:$INTERNALHOSTNAME
			" $AMAZONIIDSFILE
			
			#Any time we change instances we have to update the apacheconfig
			SOMETHINGHASCHANGED="1"

        fi

	fi


done < "$INSTANCESFILEIVU"


#Any time we change instances we have to update the apacheconfig
if [ "$SOMETHINGHASCHANGED" == "1" ]; then
    ./log-status-blue.sh "An instance has changed, services may need to be updated"
fi

if [ "$ALLISWELL" == "1" ]; then
    ./log-status.sh "Instances AllIsWell `date`"
fi

