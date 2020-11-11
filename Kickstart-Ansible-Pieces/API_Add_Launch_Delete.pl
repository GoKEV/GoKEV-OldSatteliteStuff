#!/usr/bin/perl

#	This script, when executed on the newly-provisioned server, is intended
#	to reach out to Ansible Tower and perform the following:
#		1 - Insert "this server" manually into an inventory
#		2 - Perform an API call to launch a job
#		3 - Delete "this server" from that manual inventory
#
#	Keep in mind, this goes against the licensing agreement of Ansible Tower if
#	you are intentionally using this to overprovision your Tower server.  This
#	process is also useful for certain Red Hat embedded customers or Tower
#	customers who need a flexible way to combat certain errors in newly-provisioned
#	servers which don't yet show in a dynamic Tower inventory
#
#	Use at your own risk and test repeatedly before deploying anywhere important.
#	ENJOY!!
#	Kevin Holmes :: Kev@GoKEV.com

#  The following assumes: a manual inventory set up with ADMIN permissions
#  assigned to the limited user (noted as user:password below).  My
#  "Provisioning" inventory is inventory #11.
#
#
#  VARS TO SET:

# Set this to 0 if you want to delete the new inventory item when the playbook is done
$nodelete = 1;

# Switch this to 1 for verbose, 0 for silent
$output = 1;

# user credentials for the limited account, entered as     user:password
# This can also be configured as an API but this script
# hasn't been configured for that yet. See the how-to:
# http://gokev.com/ansible-tower-restful-api-using-a-token/
$userandpass = 'admin:mypassword';

# inventory ID
$invid = 4;				# This is the inventory ID where your temp servers will go
					# and will also be the one configured in your job template below.

# launch job template ID (numeric or UUencoded name:  12 or My%20Job%20Template)
$job_template_id = "ProvisionTemp";	# Change this to match your Tower Job Template

# Ansible Tower URL
$towerurl = 'https://mytower.tld';	# Change this to match your Tower base URL

# Delay this many seconds between the job launch and deleting the server from inventory.
$delay = 30;


################################################################################
###              Nothing below here should need to be modified.              ###
###                       though it might be fun!  :)                        ###
################################################################################

# This turns the IP address into a var
chomp ($newsrvname = `hostname`);
chomp ($newsrvip = `ip -4 route get 8.8.8.8`);
$newsrvip =~ s/\s+/ /g;
$newsrvip =~ s/^.*src\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s.*/$1/g;

$newsrvdesc = "API inserted $newsrvname $newsrvip";

if ($output == 1){

print<<ALLDONE;
------------------------
INVENTORYID	$invid
NEWSERVER	$newsrvname
NEWSERVERIP	$newsrvip
TEMPLATEID	$job_template_id
TOWERURL	$towerurl
ALLDONE

}


## This defines the curl command with which we INSERT
$insert =<<ALLDONE;
curl -s -f -k -H 'Content-Type: application/json' -XPOST -d '{
	"name": "$newsrvname",
	"description": "$newsrvdesc",
	"inventory": "$invid",
	"variables": "ansible_host: $newsrvip",
	"enabled": true
}' --user $userandpass $towerurl/api/v2/hosts/ 2>&1

ALLDONE

$insert =~ s/\s+/ /g;

## Parse the reply and extract the first piece of it... next, take the small chunk and remove everything that's not a digit.
($newsrvid,undef) = split (/\,/,`$insert`);
$newsrvid =~ s/[^0-9]//g;
print "$insert\nNEWSERVERID\t$newsrvid\n\n" if ($output == 1);

$epoch = $^T;
## This defines the command which runs API job launch
$launch =<<ALLDONE;


curl --silent -t -s -f -k -H 'Content-Type: application/json' -XPOST -d '{
	"extra_vars": {
		"HOSTS": "$newsrvname", 
		"epoch_time": "$epoch"
	} 
}' --user $userandpass $towerurl/api/v2/job_templates/$job_template_id/launch/ 2>&1

ALLDONE

$launch =~ s/\s+/ /g;

## We execute the request for the job template via API
print "LAUNCH\t\tRunning this API launch command:\n" if ($output == 1);
print "\t\t$launch\n" if ($output == 1);
chomp($jobid = `$launch`);
$jobid =~ s/^.*\:([0-9]+)\}$/$1/g;

print "\t\trunning now as job ID $jobid\n" if ($output == 1);

exit if ($nodelete == 1);

## This defines the API call to delete the new system from the inventory
$delete =<<ALLDONE;
curl -k -H 'Content-Type: application/json' -XDELETE --user $userandpass $towerurl/api/v2/hosts/$newsrvid/ 
ALLDONE


## Race condition!!  We can't delete from inventory until the playbook starts
if ($output == 1){
print<<ALLDONE;
DELAY SET	$delay seconds
DELAYING	We need to delay $delay seconds to make sure the playbook is running before deleting the server
ALLDONE
}
sleep($delay);


## We execute the delete command and finish out
if ($output == 1){
print<<ALLDONE;
FINISHING	Deleting $newsrvname (ID $newsrvid) from inventory $invid.

		This should be plenty of delay, but if the job is failing due to
		inventory issues, try extending the delay value in the variables
		settings area of this script, currently $delay seconds.

ALLDONE

}

system($delete);


