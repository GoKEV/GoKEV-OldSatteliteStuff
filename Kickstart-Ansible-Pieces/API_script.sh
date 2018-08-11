#!/bin/sh

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

# inventory ID
INVID=11

# callback template ID
CBKID=152

# This turns the FQDN into a var (you might want to use an IP if your DNS isn't configured yet at this point in the build)
NEWSRVNAME=`hostname -f`

## This runs the API call and grabs the new server ID from the output text:
NEWSRVID=`curl -s -f -k -H 'Content-Type: application/json' -XPOST -d '{"name": "$NEWSRVNAME", "description": "Manually Inserted Server", "inventory": "$INVID", "enabled": true }' --user user:password https://ansibletower.lab/api/v1/hosts/ | cut -f 2 -d ":" | sed 's/\,.*$//g'`


## This runs the provisioning callback
echo running provisioning callback for template $CBKID on server $NEWSRVNAME ID number: $NEWSRVID
curl --insecure --data "host_config_key=KEV" https://ansibletower.lab:443/api/v1/job_templates/$CBKID/callback/


## This uses an API call to delete the server from inventory
echo deleting $NEWSRVID
echo curl -s -f -k -H 'Content-Type: application/json' -XDELETE --user user:password https://ansibletower.lab/api/v1/hosts/$NEWSRVID/



