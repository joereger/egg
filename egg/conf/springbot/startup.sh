#! /bin/bash
# Startup script to call the web infrastructure to tell it that
# this resource is ready to serve some web action.

#Set up EC2 vars
export EC2_HOME=/home/ec2-user/.ec2/ec2-api-tools-1.5.2.3
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=/home/ec2-user/.ec2/pk-***REMOVED***.pem
export EC2_CERT=/home/ec2-user/.ec2/cert-***REMOVED***.pem
export PATH=/home/ec2-user/.ec2/ec2-api-tools-1.5.2.3/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/jre

#Report to log
echo "______________STARTUP" >> /home/ec2-user/egg/logs/startup.log
echo `date` >> /home/ec2-user/egg/logs/startup.log
echo "Hello from startup.sh" >> /home/ec2-user/egg/logs/startup.log


#Associate Elastic IP
$EC2_HOME/bin/ec2-associate-address -K $EC2_PRIVATE_KEY -C $EC2_CERT 107.22.246.218 -i i-6e4d0d0c
if [ $? != 0 ]; then
   echo "Error associating elastic ip" >> /home/ec2-user/egg/logs/startup.log
else 
   echo "Success associating elastic ip" >> /home/ec2-user/egg/logs/startup.log	
fi


#Report to log
echo "End of startup.sh reached" >> /home/ec2-user/egg/logs/startup.log
