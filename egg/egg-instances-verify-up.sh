#!/bin/bash

source common.sh




		
#Read INSTANCESFILE
 exec 3<> $INSTANCESFILE; while read line_instances_ivu <&3; do {
	if [ $(echo "$line_instances_ivu" | cut -c1) != "#" ]; then
	
		LOGICALINSTANCEID=$(echo "$line_instances_ivu" | cut -d ":" -f1)
		SECURITYGROUP=$(echo "$line_instances_ivu" | cut -d ":" -f2)
		INSTANCESIZE=$(echo "$line_instances_ivu" | cut -d ":" -f3)
		AMIID=$(echo "$line_instances_ivu" | cut -d ":" -f4)
		ELASTICIP=$(echo "$line_instances_ivu" | cut -d ":" -f5)
		EBSVOLUME=$(echo "$line_instances_ivu" | cut -d ":" -f6)
		EBSDEVICENAME=$(echo "$line_instances_ivu" | cut -d ":" -f7)


		#First, determine whether this instance should be up based on time
		#Will use this later on for time-based scaling or load-based scaling
		#Note that logical flow is already taken care of below
		SHOULDBEUP=1
		
		#Default AMIID
		if [ "$AMIID" == "" ]; then
			AMIID="ami-08728661"
		fi
		
		#Read AMAZONIIDSFILE
		AMAZONINSTANCEID=""
		HOST=""
		exec 4<> $AMAZONIIDSFILE; while read amazoniidsline <&4; do {
			if [ $(echo "$amazoniidsline" | cut -c1) != "#" ]; then
				LOGICALINSTANCEID_A=$(echo "$amazoniidsline" | cut -d ":" -f1)
				if [ "$LOGICALINSTANCEID_A" == "$LOGICALINSTANCEID" ]; then
					AMAZONINSTANCEID=$(echo "$amazoniidsline" | cut -d ":" -f2)
					HOST=$(echo "$amazoniidsline" | cut -d ":" -f3)
				fi
			fi
		}; done; exec 4>&-

		
		#Determine whether this instance is running
		thisinstanceisup=0
		export RUNNING="running"
		export status=`${EC2_HOME}/bin/ec2-describe-instances $AMAZONINSTANCEID | grep INSTANCE | cut -f6`
		if [ "$status" == "$RUNNING" ]; then
			export thisinstanceisup=1
			#./pulse-update.sh "Instance$LOGICALINSTANCEID" "OK"
		fi
		#./log.sh "Thisinstanceisup=$thisinstanceisup"
		
		#Start an instance if necessary
		if [ "${thisinstanceisup}" == "0" ]; then

		    #Instance not up, should it be?
		    if [ "$SHOULDBEUP" == "1" ]; then

                ./pulse-update.sh "Instance$LOGICALINSTANCEID" "CREATING"
                ./log-status-red.sh "Instance $LOGICALINSTANCEID not found, will create"
                ./mail.sh "Instance$LOGICALINSTANCEID not found, creating" "stand up!!!!!!!!!"

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
                export iid=`${EC2_HOME}/bin/ec2-run-instances ${AMIID} -t $INSTANCESIZE -z ${zone} -k ${key} -g ${securitygroup1} -g ${securitygroup2} | grep INSTANCE | cut -f2`
                if [ $? != 0 ]; then
                   ./pulse-update.sh "Instance$LOGICALINSTANCEID" "ERROR STARTING INSTANCE"
                   ./log-status-green.sh "Error starting instance for amazonimageid ${AMIID}"
                   continue
                fi
                ./pulse-update.sh "Instance$LOGICALINSTANCEID" "WAIT FOR RUN"
                ./log.sh "Amazon iid=$iid created, waiting for it to be RUNNING"

                # Loop until the status changes to .running.
                export RUNNING="running"
                export done="false"
                export RUNNINGATTEMPTS=0
                RUNNINGSUCCESS=1
                while [ $done == "false" ]
                do
                   export status=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f6`
                   if [ $status == ${RUNNING} ]; then
                      export done="true"
                   else
                      ./log.sh "Sleeping 10 seconds for instance to be RUNNING"
                      sleep 10
                   fi
                   RUNNINGATTEMPTS=$(( $RUNNINGATTEMPTS + 1 ))
                   if [ "$RUNNINGATTEMPTS" == "20" ]; then
                      RUNNINGSUCCESS=0
                      export done="true"
                      ./log-status-red.sh "EBS running fail {$iid}"
                   fi
                done

                if [ "$RUNNINGSUCCESS" == "1" ]; then
                    ./log.sh "Instance ${iid} is RUNNING"
                    #Add Tag(s)
                    ./pulse-update.sh "Instance$LOGICALINSTANCEID" "ADDING TAG"
                    ./log.sh "Starting to add tag"
                    ec2-create-tags ${iid} --tag Name="${EC2NAMETAG}"
                    ./log.sh "Tag ${EC2NAMETAG} added to Instance ${iid}"

                    # Associate the Elastic IP with the instance
                    if [ "$ELASTICIP" != "" ]; then
                        ./log.sh "Associating elastic IP address $ELASTICIP"
                        ${EC2_HOME}/bin/ec2-associate-address $ELASTICIP -i ${iid}
                        ./pulse-update.sh "Instance$LOGICALINSTANCEID" "EIP WAIT"
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
                        export sshcheck=`ssh $HOST "[ -d ./ ] && echo yipee"`
                        if [ "$sshcheck" == "$sshtest" ]; then
                            export sshdone="true"
                        else
                            ./pulse-update.sh "Instance$LOGICALINSTANCEID" "SSH WAIT"
                            ./log.sh "SSH not up yet, sleeping 10 seconds."
                            sleep 10
                        fi
                    done
                    ./log.sh "SSH is running"

                    #Uninstall sendmail
                    ./log.sh "Uninstalling sendmail"
                    sendmailuninstall=`ssh -t -t $HOST "sudo yum -y remove sendmail"`
                    #echo $sendmailuninstall
                    ./log.sh "Done uninstalling sendmail"


                    #Remap port 25 to port 8025 so that Java can bind to it when running as non-root user
                    iptablesremap=`ssh -t -t $HOST "sudo iptables -t nat -A PREROUTING -p tcp --dport 25 -j REDIRECT --to-port 8025"`
                    ./log.sh "iptablesremap=$iptablesremap"
                    ./log.sh "Done remapping port 25 to port 8025"

                    #Attach EBS volumes if necessary
                    EBSMOUNTSUCCESS=1
                    if [ "$EBSVOLUME" != "" ]; then
                        ./pulse-update.sh "Instance$LOGICALINSTANCEID" "INSTALLING XFSPROGS"
                        ssh -t -t $HOST "sudo yum -y install xfsprogs"
                        ./pulse-update.sh "Instance$LOGICALINSTANCEID" "EBS MOUNTING"
                        # Attach the volume to the running instance
                        # For future reference here's what I did to the volume to create the file system
                        # sudo yum install xfsprogs
                        #grep -q xfs /proc/filesystems || sudo modprobe xfs
                        #sudo mkfs.xfs /dev/sdh
                        #Note that this filesystem creation is done manually and only once to make the EBS volume usable
                        ./log.sh "Attaching volume ${EBSVOLUME}"
                        ${EC2_HOME}/bin/ec2-attach-volume ${EBSVOLUME} -i ${iid} -d ${EBSDEVICENAME}
                        ./log.sh "Sleeping 10 sec for volume to attach"
                        sleep 10
                        # Loop until the volume status changes to "attached"
                        export COUNTMOUNTATTEMPTS=0
                        export ATTACHED="attached"
                        export done="false"
                        while [ $done == "false" ]
                        do
                           export status=`${EC2_HOME}/bin/ec2-describe-volumes | grep ATTACHMENT | grep ${EBSVOLUME} | cut -f5`
                           if [ "$status" == "${ATTACHED}" ]; then
                               export done="true"
                               ./log.sh "EBS volume mount success ${iid} ${EBSVOLUME} ${EBSDEVICENAME}"
                               #Configure the instance to have the drive on reboot and to have it mounted as /vol
                               sshtmp1=`ssh -t -t $HOST "echo '/dev/sdh /vol xfs noatime 0 0' | sudo tee -a /etc/fstab"`
                               echo $sshtmp1
                               sshtmp2=`ssh -t -t $HOST "sudo mkdir -m 000 /vol"`
                               echo $sshtmp2
                               sshtmp3=`ssh -t -t $HOST "sudo mount /vol"`
                               echo $sshtmp3
                           else
                              ./log.sh "Sleeping 10 sec for volume to attach, status=$status"
                              sleep 10
                           fi
                           COUNTMOUNTATTEMPTS=$(( $COUNTMOUNTATTEMPTS + 1 ))
                           if [ "$COUNTMOUNTATTEMPTS" == "10" ]; then
                              EBSMOUNTSUCCESS=0
                              export done="true"
                              ./log-status-red.sh "EBS volume mount fail ${iid} ${EBSVOLUME} ${EBSDEVICENAME}"
                           fi
                        done
                    fi

                    #Delete any current line with this logicalinstanceid
                    sed -i "
                    /^${LOGICALINSTANCEID}:/ d\
                    " $AMAZONIIDSFILE

                    if [ "$EBSMOUNTSUCCESS" == "1" ]; then
                        ./pulse-update.sh "Instance$LOGICALINSTANCEID" "OK, BUT NEW"
                        #Write a record to amazoniids.conf
                        sed -i "
                        /#BEGINDATA/ a\
                        $LOGICALINSTANCEID:$AMAZONINSTANCEID:$HOST:$INTERNALHOSTNAME
                        " $AMAZONIIDSFILE
                    else
                        ./pulse-update.sh "Instance$LOGICALINSTANCEID" "EBS MOUNT FAIL, TERMINATING"
                        ./egg-instance-terminate.sh $LOGICALINSTANCEID
                    fi

                else
                    ./pulse-update.sh "Instance$LOGICALINSTANCEID" "RUNNING FAIL, TERMINATING"
                    ./egg-instance-terminate.sh $LOGICALINSTANCEID
                fi

            fi

        else
            #Instance is up, should it be?
            if [ "$SHOULDBEUP" == "0" ]; then
                #Shutdown this instance
                ./pulse-update.sh "Instance$LOGICALINSTANCEID" "SHUTTING DOWN BECAUSE OF TIME"
                ./egg-instance-terminate.sh $LOGICALINSTANCEID
                ./pulse-update.sh "Instance$LOGICALINSTANCEID" "SHUT DOWN BECAUSE OF TIME"
            fi
        fi

	fi


}; done; exec 3>&-



