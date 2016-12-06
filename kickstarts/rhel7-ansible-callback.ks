install
url --url http://satellite.labtop/pulp/repos/0465a0f7-ca4c-49f7-8a39-bacf1e33c5d2/Library/content/dist/rhel/server/7/7.2/x86_64/kickstart/
lang en_US.UTF-8
selinux --disabled
keyboard us
skipx

network --bootproto dhcp 
rootpw --iscrypted $5$UJVcZzAe$4i6jlDxECSe9t8L5Kt/ZFhPPinuiyOjeW8kjVGKPrED
firewall --service=ssh
authconfig --useshadow --passalgo=sha256 --kickstart
timezone --utc US/Eastern

bootloader --location=mbr --append="nofb quiet splash=quiet" 

zerombr
clearpart --all --initlabel
part  /boot     --asprimary  --size=500
part  / --asprimary --size=1024  --grow
part  swap --size=1024  --maxsize=2048 --grow

#zerombr
#clearpart --all --initlabel
#autopart

text
reboot

%packages --ignoremissing
yum
dhclient
ntp
wget
screen
nano
perl
rsync
yum-utils
@Core
%end

%post --nochroot
exec < /dev/tty3 > /dev/tty3
#changing to VT 3 so that we can see whats going on....
/usr/bin/chvt 3
(
cp -va /etc/resolv.conf /mnt/sysimage/etc/resolv.conf
/usr/bin/chvt 1
) 2>&1 | tee /mnt/sysimage/root/install.postnochroot.log
%end

%post
logger "Starting anaconda rhel7ks.labtop postinstall"
exec < /dev/tty3 > /dev/tty3
#changing to VT 3 so that we can see whats going on....
/usr/bin/chvt 3
(


#  interface
real=`ip -o link | head -n 2 | tail -n 1 | awk '{print $2;}' | sed s/:$//`
realmac=`ip -o link | head -n 2 | tail -n 1 | sed "s/^.*\([0-9a-f].:[0-9a-e].:[0-9a-f].:[0-9a-f].:[0-9a-f].:[0-9a-f].\).*$/\1/g"`

# ifcfg files are ignored by NM if their name contains colons so we convert colons to underscore
sanitized_real=$real

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$sanitized_real
BOOTPROTO="dhcp"
DEVICE=$real
HWADDR="$realmac"
ONBOOT=yes
PEERDNS=yes
PEERROUTES=yes
EOF


#update local time
echo "updating system time"
/usr/sbin/ntpdate -sub 0.fedora.pool.ntp.org
/usr/sbin/hwclock --systohc


  # add subscription manager
 
  yum -t -y -e 0 install subscription-manager
  rpm -ivh http://satellite.labtop/pub/katello-ca-consumer-latest.noarch.rpm
 

  echo "Registering the System"
  subscription-manager register --org="0465a0f7-ca4c-49f7-8a39-bacf1e33c5d2" --activationkey="RHEL7KS"
  subscription-manager repos --enable=rhel-*-satellite-tools-*-rpms
  yum clean all
  yum -y install ansible katello-agent rsync



  echo "Enabling Satellite Tools Repo"
  echo "DEPRECATED: This may be removed in a future version of Satellite, please add Satellite Tools to your activation key(s)."
  
  echo "Installing Katello Agent"
  yum -t -y -e 0 install katello-agent
  chkconfig goferd on
  




# update all the base packages from the updates repository
yum -t -y -e 0 update



mkdir -p ~root/.ssh

cat << EOF >> ~root/.ssh/authorized_keys
## ROOT/KEV @ LabTop
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+CtuMWesodYXXtAuy5qNInyugZy9lbCKRHTDn0V0mwMVJ2gmni5QLVgyc7TW6bvvRsEviV6yJKibQVxyMPVgSCwFbwq0KZ89j20XVSYaGZBv6nlJjngXU5G3QWaq9MPRwXUFNOToGPabKJ0C/DAZyVNhg6WbuF619DSM98CHHEqOj1tdvoU2thE6vwj+6cZ9PcZPfKm+9jaKuU5Cq1h6/WpE+sJ5N+Q0mZ7yAXbyduDLpbZlyth3X0lxAO2t95yy8U0D82dvANbUvgUmjj+6LyrUyID408TZt4Hx9HyTswqazMEqBrgdp237+N+4HOhq/lw7bHwm9spljs/DGpYhn kevin@kev.labtop

## Satellite
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDF3W7eHL5Rzaq/LFIhTLrha+O7hoSkXVbW0vQl6dOideZBAiAlhe0H11+g7M3BQXUGLHee+YrxpcXjYfIKKZzTg4TQd/Noc4baTIoB7JVHHJDPMcV+1cOuIXljEGxHbe/eSxWVPKXMeP+dVbqGc0lG0SI9opIOVuPI7WxG5lNu3bFcICHNkTns0GnRQnmxxdbRCmUID0lwITwMYkjVi7FaX9IHiJthR/g22jCK0oRcy1SmfCs1f+ufGx+Gc/kqDRSud3vRyOwWPvsTC8k8JUmaPvaHvnJTJbMguPiC3h1hTKOEVEHPV07OaHKnRPCye4JaWlrs0hcUerlPuR6JQvF/ root@satellite.labtop
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDtVDSKW2hr1OxIf9KhJRLeL4Ge43sFR/C1bu6FS/fURODclGu91JYN5+frrdTPOZeN0JFbFuV6POJbutASTiGtxJMT/luG4vRorCR2RASdUoGQuvZR3/fiQVJNRGd40lFQgtgeetJzCbWRz1J9F+TpKXYAI/3xO0C02oVifOXpTT1zjKIaJ9yqseFBW6iy8fg+L3+amLsajTbjrotAID2RL8QrQH/qNkIpMwx9Wvwqc9NT5mGU1Sh0GCzC7CPQi1h5HiUf0l/Q7XkEQq/PQkDAycn4AEwUfuF7Itc+HHbbsPQN2KUgBUqo210BHvmRmi5H8PF2AA4StxHY25fMYgEP foreman-proxy@satellite.labtop

## Tower
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwJKTrsk/aU5qr8ubdchfqtxkDVpeF8+U/m7HOrvOUKIVP7qfzZv95eH4+TTxoivXWl3TwxRuWHFr8q1mFxMooUZZNNJii4TdLaDaFQjPa8Wsfhibw9S1mUJiPhOpIuSCVZW+JbP2LnZ6SR32ZV8ZfobrxRyh/z8ZrmGPhwN2/TZtr10fL0Y/Tanlv/JeJNdqIVmyv6ewYwURnO4n9PnmGTGvtYFDpt5p4mqmDWuck0dUu29YaOf85MIjZWIgXo4Fr0K960zoJJb4k7QwNCRuGPL4q5zeM9EXB5YDubeiN9e/PV2FAKeEayxH41eWP1sX1W8bKCUvxc4o5Vhlock4x root@ansibletower.labtop

EOF


chmod 700 ~root/.ssh
chmod 600 ~root/.ssh/authorized_keys
chown -R root: ~root/.ssh

# Restore SELinux context with restorecon, if it's available:
command -v restorecon && restorecon -RvF ~root/.ssh || true


sync

# Inform the build system that we are done.


cat << EOF > /usr/lib/systemd/system/ansible-firstboot.json
{
  "host_config_key": "KEV" ,
  "extra_vars": {
    "rebootrequired": "yes"
  }
}

EOF


cat << EOF > /usr/lib/systemd/system/ansible-firstboot.service
[Unit]
Description=Provisioning callback to Ansible
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot


ExecStart=/usr/bin/curl -kfH 'Content-Type: application/json' -XPOST -d @/usr/lib/systemd/system/ansible-firstboot.json https://ansibletower:443/api/v1/job_templates/35/callback/
ExecStartPost=/usr/bin/systemctl disable ansible-firstboot

[Install]
WantedBy=multi-user.target

EOF


systemctl enable ansible-firstboot.service



) 2>&1 | tee /root/install.post.log

exit 0

%end
