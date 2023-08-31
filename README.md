# egg

Egg is a bash-based precursor to Puppet/Chef, before those things existed/were mature enough.

For years I ran 30ish apps (eight-ish codebases, multiple instances per client) across 20ish physical servers at a datacenter. Late night runs to fix hard drives, reinstall OSes and generally curse at the moon. 

Then Amazon AWS came along and I was able to light up a server via code.  Revolutionary.

Egg started as a single bash script to fire up a new server.  Then I added a heartbeat check.  Then I added a deployer.  And then, and then, and then.

Eventually I had built a full deployment system that could stand up a rather large 30ish server cluster consisting of app servers and databases completely via configuration.  

I kept the logical definition of the cluster in just a couple files.  

Eventually Egg reached 109 unique bash scripts that all worked together to keep an infrastructure deployed and running that consisted of:
- Apache http servers
- Tomcat app servers
- MySQL databases
- Terracotta key/val cache servers
- MongoDB databases

It could detect issues at the server, service and system level and tear things completely down and spin them back up.  This improved my quality of life dramatically.

I learned a lot about bash and linux systems. But mostly I learned the power of configuration coupled with cloud servers.

It was no surprise to me when Heroku and similar Paas platforms great.  And when Chef/Puppet matured.  And when Docker took off.

Nowadays it's a quaint reminder to me of how investments in automation focus your technology to conform to functional and improved outcomes.  Bash scripts aren't great with nuance.  They wring every last drop of silly code out of your platform and leave you in a much happier place.
