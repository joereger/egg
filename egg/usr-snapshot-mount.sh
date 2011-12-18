#!/bin/bash

source common.sh

echo "Finding snapshots... please wait."
COUNT=0
SNAPSHOTID=""
SNAPDESC=""
${EC2_HOME}/bin/ec2-describe-snapshots | sort -k 5 |
while read line; do
    if [ $(echo "$line" | cut -f1) == "SNAPSHOT" ]; then
  	    SNAPSHOTID=$(echo "$line" | cut -f2)
	    SNAPDATE=$(echo "$line" | cut -f5)
	    SNAPDESC="$(echo "$line" | cut -f9) $(echo "$line" | cut -f10) $(echo "$line" | cut -f11) $(echo "$line" | cut -f12) $(echo "$line" | cut -f13)"
	    COUNT=$(( $COUNT + 1 ))
	    echo "$COUNT - ${SNAPSHOTID} ${SNAPDATE} ${SNAPDESC}"
	fi
done

echo "Send which snapshot to S3? (Type the number and hit enter)"

COUNT=0
read CHOSENCOUNT
echo "Looking up snapshot... please wait."
if [ "$CHOSENCOUNT" != "" ]; then

    ${EC2_HOME}/bin/ec2-describe-snapshots | sort -k 5 |
    while read line; do
        if [ $(echo "$line" | cut -f1) == "SNAPSHOT" ]; then
            COUNT=$(( $COUNT + 1 ))
            if [ "$CHOSENCOUNT" == "$COUNT" ]; then
                SNAPSHOTID=$(echo "$line" | cut -f2)
                SNAPDESC="$(echo "$line" | cut -f9) $(echo "$line" | cut -f10) $(echo "$line" | cut -f11) $(echo "$line" | cut -f12) $(echo "$line" | cut -f13)"

                ZONE="us-east-1c"

                echo "Creating volume from ${SNAPSHOTID} ${SNAPDESC}"
                ${EC2_HOME}/bin/ec2-create-volume --snapshot $SNAPSHOTID -z $ZONE |
                while read line; do
                    echo $line
                    EBSVOLUMEID=$(echo "$line" | cut -f2)
                    echo "Volume ${EBSVOLUMEID} created"

                    echo "Adding tag EGGSNAPSHOTMOUNT to vol"
                    echo `${EC2_HOME}/bin/ec2-create-tags ${EBSVOLUMEID} --tag Name=EGGSNAPSHOTMOUNT`


                    echo "Creating instance"
                    INSTANCESIZE="t1.micro"
                    AMIID="ami-08728661"
                    ZONE="us-east-1c"
                    KEY="joekey"
                    SECURITYGROUP="default"

                    export iid=`${EC2_HOME}/bin/ec2-run-instances ${AMIID} -t ${INSTANCESIZE} -z ${ZONE} -k ${KEY} -g ${SECURITYGROUP} | grep INSTANCE | cut -f2`
                    if [ $? != 0 ]; then
                       echo "ERROR STARTING INSTANCE"
                       continue
                    fi
                    echo "Instance $iid created, waiting for it to be RUNNING"

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
                          echo "Sleeping 10 seconds to wait for instance to be RUNNING"
                          sleep 10
                       fi
                       RUNNINGATTEMPTS=$(( $RUNNINGATTEMPTS + 1 ))
                       if [ "$RUNNINGATTEMPTS" == "20" ]; then
                          RUNNINGSUCCESS=0
                          export done="true"
                          echo "Instance {$iid} FAIL to start"
                       fi
                    done

                    if [ "$RUNNINGSUCCESS" == "1" ]; then
                        echo "Instance ${iid} is RUNNING"
                        #Add Tag(s)
                        echo "Adding tag EGGSNAPSHOTMOUNT"
                        ec2-create-tags ${iid} --tag Name="EGGSNAPSHOTMOUNT"
                        echo "Tag EGGSNAPSHOTMOUNT added to Instance ${iid}"

#                        # Associate the Elastic IP with the instance
#                        if [ "$ELASTICIP" != "" ]; then
#                            ./log.sh "Associating elastic IP address $ELASTICIP"
#                            ${EC2_HOME}/bin/ec2-associate-address $ELASTICIP -i ${iid}
#                            ./pulse-update.sh "Instance$LOGICALINSTANCEID" "EIP WAIT"
#                            ./log.sh "Waiting 30 seconds for elasticip to be assigned"
#                            sleep 30
#                        fi

                        echo `${EC2_HOME}/bin/ec2-describe-instances ${iid}`

                        #Get the IP address
                        export ipaddress=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f18`
                        echo "Internal IP Address of ${iid} is ${ipaddress}"

                        #Get the external IP address
                        export externalipaddress=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f17`
                        echo "External IP Address of ${iid} is ${externalipaddress}"

                        #Get the internalhost address
                        export INTERNALHOSTNAME=`${EC2_HOME}/bin/ec2-describe-instances ${iid} | grep INSTANCE | cut -f5`
                        echo "Internal Host of ${iid} is ${INTERNALHOSTNAME}"

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
                                echo "SSH not up yet, sleeping 10 seconds."
                                sleep 10
                            fi
                        done
                        echo "SSH is running"


                        #Attach EBS volumes if necessary
                        EBSMOUNTSUCCESS=1
                        if [ "$EBSVOLUMEID" != "" ]; then
                            echo "Installing XFSPROGS"
                            ssh -t -t $HOST "sudo yum -y install xfsprogs"
                            # Attach the volume to the running instance
                            # For future reference here's what I did to the volume to create the file system
                            # sudo yum install xfsprogs
                            #grep -q xfs /proc/filesystems || sudo modprobe xfs
                            #sudo mkfs.xfs /dev/sdh
                            #Note that this filesystem creation is done manually and only once to make the EBS volume usable
                            EBSDEVICENAME="/dev/sdh"
                            echo "Attaching ${EBSVOLUMEID} to ${EBSDEVICENAME}"
                            ${EC2_HOME}/bin/ec2-attach-volume ${EBSVOLUMEID} -i ${iid} -d ${EBSDEVICENAME}
                            echo "Sleeping 10 sec for volume to attach"
                            sleep 10
                            # Loop until the volume status changes to "attached"
                            export COUNTMOUNTATTEMPTS=0
                            export ATTACHED="attached"
                            export done="false"
                            while [ $done == "false" ]
                            do
                               export status=`${EC2_HOME}/bin/ec2-describe-volumes | grep ATTACHMENT | grep ${EBSVOLUMEID} | cut -f5`
                               if [ "$status" == "${ATTACHED}" ]; then
                                   export done="true"
                                   echo "EBS volume mount SUCCESS ${iid} ${EBSVOLUMEID} ${EBSDEVICENAME}"
                                   #Configure the instance to have the drive on reboot and to have it mounted as /vol
                                   echo "Configure vol to work after reboot"
                                   sshtmp1=`ssh -t -t $HOST "echo '/dev/sdh /vol xfs noatime 0 0' | sudo tee -a /etc/fstab"`
                                   echo $sshtmp1
                                   echo "Make directory /vol"
                                   sshtmp2=`ssh -t -t $HOST "sudo mkdir -m 000 /vol"`
                                   echo $sshtmp2
                                   echo "Mount EBS volume to /vol"
                                   sshtmp3=`ssh -t -t $HOST "sudo mount /vol"`
                                   echo $sshtmp3
                                   echo "Chmod 777 /vol"
                                   sshtmp4=`ssh -t -t $HOST "sudo chmod 777 -R /vol"`
                                   echo $sshtmp4
                               else
                                  echo "Sleeping 10 sec for volume to attach, status=$status"
                                  sleep 10
                               fi
                               COUNTMOUNTATTEMPTS=$(( $COUNTMOUNTATTEMPTS + 1 ))
                               if [ "$COUNTMOUNTATTEMPTS" == "10" ]; then
                                  EBSMOUNTSUCCESS=0
                                  export done="true"
                                  echo "EBS volume mount FAIL ${iid} ${EBSVOLUMEID} ${EBSDEVICENAME}"
                               fi
                            done
                        fi





                        echo "-"
                        echo "${EBSVOLUMEID} mounted at /vol on ${iid} at ${externalipaddress}"
                        echo "Use sFTP to access the files"



                    fi

                done


            fi
        fi
    done
fi









		
