# Server Provisioning Templates

[![N|Solid](http://gokev.com/GoKEVicon300.png)](https://goKev.com)

This is a set of stuff to go along with a Red Hat Satellite Server 6.x implementation
  - PXE boot config menu
  - RHEL kickstart files for RHEL6 and RHEL7
  - Ansible playbooks for post-install

> This set of files will allow you to network/iPXE boot a new baremetal image with the included PXE config.  The included kickstart files will then include an Ansible playbook callback to Anbsible Tower

### Installation / implementation

There's no easy way to give instructions how to use these unless you've already implemented Ansible Tower and Red Hat Satellite Server 6.x.  Assuming that's the case, here are the components to consider:

* [Ansible Tower Playbooks] - Link this to the git repository for Lab-Playbooks.  This is configured in Ansible Tower under "projects", then added into "job templates"
* [Ansible Tower Provisioning Callback] - Set up your job template with a callback URL.  Replace the one in these kickstarts to match.  This is configured in Ansible Tower under "job templates"
* [pxeboot.cfg] - drop the 'default' file in there and make sure your paths to images and kickstarts match what's being offered from your Satellite Server.  This 'default' file includes the menu that allows you to pick a type of build.  Some people will reduce the wait time on this and have it set to automatically pick their favorite method (and even clear out options they don't want).  Tear it up!  Have fun!!
* [kickstarts] - This is the file that will end up on your server in /root/anaconda-ks.cfg once the first boot is complate.  The included KS is a fairly standard "thin" KS that includes some of my publickeys, along with a snippet at the end which calls the Ansible Tower Provisioning Callback URL.

### How it works

* The new server (baremetal or virtual) PXE boots to your preconfigured network-bootable environment.  Your Red Hat Satellite 6 server offers up the 'default' file in the pxeboot.cfg directory. and the first thing the new server displays is a menu with options.  Pick the... oh, let's pick the RHEL7 boot with an Ansible Callback.

* The selection points to a boot image and stuff -- we hope this is already in place and configured with Satellite.  it should be if you made it this far.  The details in the 'default' boot menu pass along a kernel parameter:  ks=http.....mykickstartfile

* Once the server boots to the init img and passes reference to your kickstart file, the install begins.  The kickstart we selected will automatically wipe the drive and lay down a filesystem.  It installs a few simple packages (rsync is required becaue our playbooks include a sync function, which relies on it).  We also lay down some publickeys so our Ansible Tower instance can connect on the first try.  Replace these with yours.

* Lastly, once the basics of the kickstart are complete, the last 20 lines or so of the KS -- we lay down a one-time service that will automatically call Ansible Tower on the first boot.  This provisioning callback triggers Ansible Tower to run the newserver.yaml playbook, installing all sorts of cool standard files that we define in that and the included plays/ directory.

* The very last step of the Ansible playbook run is to delete the temporary services we created -- so it only runs once.  Since we were successful, we complete the playbook, reboot, and confirm that the server comes back up before marking the playbook as "success".

* Now go play with your newly provisioned server!




