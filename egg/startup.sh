#! /bin/bash
# Startup script to call the web infrastructure to tell it that
# this resource is ready to serve some web action.

source common.sh

#Report to log
echo "Hello from joestartup.sh" >> /home/ec2-user/egg/joestartup.log
echo `date` >> /home/ec2-user/egg/joestartup.log

#Associate Elastic IP
$EC2_HOME/bin/ec2-associate-address -K $EC2_PRIVATE_KEY -C $EC2_CERT 184.73.230.222 -i i-03c7116f
echo "EC2 Elastic IP association attempt complete" >> /home/ec2-user/egg/joestartup.log

#Report to log
echo "End of joestartup.sh reached" >> /home/ec2-user/egg/joestartup.log
