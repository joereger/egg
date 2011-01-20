#! /bin/bash
# Startup script to call the web infrastructure to tell it that
# this resource is ready to serve some web action.

echo "Hello from joestartup.sh" >> /home/ec2-user/egg/joestartup.log
echo `date` >> /home/ec2-user/egg/joestartup.log


#Set up EC2 vars
export EC2_HOME=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308
export PATH=$PATH:$EC2_HOME/bin
export EC2_PRIVATE_KEY=/home/ec2-user/.ec2/pk-***REMOVED***.pem
export EC2_CERT=/home/ec2-user/.ec2/cert-***REMOVED***.pem
export PATH=/home/ec2-user/.ec2/ec2-api-tools-1.3-62308/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/jre


#Associate Elastic IP
$EC2_HOME/bin/ec2-associate-address -K $EC2_PRIVATE_KEY -C $EC2_CERT 184.73.230.222 -i i-03c7116f
echo "EC2 Elastic IP association attempt complete" >> /home/ec2-user/egg/joestartup.log

#Report to log
echo "End of joestartup.sh reached" >> /home/ec2-user/egg/joestartup.log
