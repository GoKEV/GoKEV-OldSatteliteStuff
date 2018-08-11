#!/bin/sh
################################################################################
###	
###	Basic service example to create the ansible-firstboot service.
###	This is also included in the adjacent full kickstart file, but
###	this exanple is just the Ansible callback service.  This will
###	create the file:
###		/etc/rc.d/rc3.d/S99ansible-firstboot
###	
###	The json is passed as the payload to the curl command when the
###	api callback is made.  We can squeeze in whatever variables we
###	want to pass to Ansible Tower for this job template.
###
###	I left the exact URL to my callback.  Make sure to modify it
###	to meet your needs.  I felt like leaving it intact would serve
###	as a better real-world example.  In the URL, my job template is
###	number 152 and the key is "KEV".  You will change these, as well
###	as the URL to your Ansible Tower server.
###
###	In Ansible Tower's web UI, select your Job Template, then check
###	the option "Allow Provisioning Callbacks".  Enter (or generate) a
###	HOST CONFIG KEY.  Then notice the little question mark beside the
###	field PROVISIONING CALLBACK URL.  Clicking this will open a
###	dialogue popup to show the full CURL command.  Yep, it's that simple.
###	
###	I'm passionate about simple provisioning, deployment, and server
###	management using simple, stable, and robust tools.  I hope this
###	example is helpful to you.
###
###				-Kev (at) GoKEV.com
###	
################################################################################

### Lay down the one-time service that will perform the Ansible Tower provisioning callback.  The extra variables force a reboot (will not reboot on subsequent runs unless that param is passed)
### The following gets written to a file:


cat << EOF > /etc/rc.d/rc3.d/S99ansible-firstboot

# First boot, we run the Ansible callback
/usr/bin/curl -k -f -H 'Content-Type: application/json' -XPOST -d '{"host_config_key": "KEV", "extra_vars": "{\"rebootrequired\": \"yes\"}"}' https://ansibletower:443/api/v1/job_templates/152/callback/

# and then this services removes itself, never to run again!!
/bin/rm /etc/rc.d/rc3.d/S99ansible-firstboot

EOF


# Make the script executable
chmod +x /etc/rc.d/rc3.d/S99ansible-firstboot


