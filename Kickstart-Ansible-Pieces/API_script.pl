#!/usr/bin/perl

#### re-done in Perl, based on the API calls in the .sh version of this same script

#	This script, when executed on the newly-provisioned server, is intended
#	to reach out to Ansible Tower and perform the following:
#		1 - Insert "this server" manually into an inventory
#		2 - Perform a provisioning callback
#		3 - Delete "this server" from that manual inventory
#
#	Use at your own risk and test repeatedly before deploying anywhere important.
#	ENJOY!!
#	Kevin Holmes :: Kev@GoKEV.com


#  The following assumes: a manual inventory set up with ADMIN permissions
#  assigned to the limited user (noted as user:password below).  My
#  "Provisioning" inventory is inventory #11.
#
#  This will delete the newly provisioned system from inventory when complete.
#  You can remove the DELETE call if you like.  Or it could be modified to
#  remove this from the "Provisioning" group.  As it runs below, the host is
#  removed completely after the callback, but it gets re-discovered when the 
#  scheduled template runs.
#
#  VARS TO SET:

# Switch this to 1 for verbose, 0 for silent
$output = 1;

# user credentials for the limited account, entered as     user:password
$userandpass = 'helpyhelper1:helpyhelper1';

# inventory ID
$invid = 11;

# callback template ID and key
$cbkid = 198;
$cbkey = "KEV";

# Ansible Tower URL
$towerurl = 'https://ansibletower.lab';

# Delay this many seconds between the provisioning callback and deleting the server from inventory.
$delay = 30;


################################################################################
###              Nothing below here should need to be modified.              ###
###                       though it might be fun!  :)                        ###
################################################################################

if ($output == 1){

print<<ALLDONE;
------------------------
INVENTORYID	$invid
CALLBACKID	$cbkid
CALLBACKKEY	$cbkey
TOWERURL	$towerurl
ALLDONE

}

# This turns the FQDN into a var (you might want to use an IP if your DNS isn't configured yet at this point in the build)
chomp ($newsrvname = `hostname -f`);
$newsrvdesc = "Manually Inserted Server";


## This defines the curl command with which we INSERT
$insert =<<ALLDONE;
curl -s -f -k -H 'Content-Type: application/json' -XPOST -d '{
	"name": "$newsrvname",
	"description": "$newsrvdesc",
	"inventory": "$invid",
	"enabled": true
}' --user $userandpass $towerurl/api/v1/hosts/

ALLDONE


## Parse the reply and extract the first piece of it... next, take the small chunk and remove everything that's not a digit.
($newsrvid,undef) = split (/\,/,`$insert`);
$newsrvid =~ s/[^0-9]//g;
print "NEWSERVERID\t$newsrvid\n" if ($output == 1);


## This defines the command which runs the provisioning callback
$callback =<<ALLDONE;
curl --insecure --data "host_config_key=$cbkey" $towerurl/api/v1/job_templates/$cbkid/callback/
ALLDONE

## We execute the request for the provisioning callback
print "CALLBACK\tRunning this callback command:\n" if ($output == 1);
print "\t\t$callback\n" if ($output == 1);
system($callback);


## This defines the API call to delete the new system from the inventory
$delete =<<ALLDONE;
curl -k -H 'Content-Type: application/json' -XDELETE --user $userandpass $towerurl/api/v1/hosts/$newsrvid/
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


