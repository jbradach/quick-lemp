#!/bin/bash
echo '[quick-lemp] Server Setup'
echo 'Configured for Ubuntu 14.04'
echo 'Performs basic initial setup for fresh Ubuntu installation.'
echo
read -p 'Do you want to continue? [y/N] ' -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo 'Exiting...'
  exit 1
fi
if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run with root privileges.' 1>&2
   exit 1
fi

# Users
echo -e '\n[Create New User]'
read -p 'Username: ' -r newuser
unset newpass;
echo -n 'Password: '
while IFS= read -r -s -n 1 newchar; do
  if [[ -z $newchar ]]; then
     echo
     break
  else
     echo -n '*'
     newpass+=$newchar
  fi
done
useradd $newuser -s /bin/bash -m
echo "$newuser:$newpass" | chpasswd
usermod -a -G sudo $newuser
usermod -a -G www-data $newuser

# sshd
echo -e '\n[Configuring sshd and iptables]'
read -p 'New SSH Port: ' -i '22'-r newssh
sed -i.bak -e "s/^Port 22/Port $newssh/" \
  -e "s/^PermitRootLogin yes/PermitRootLogin no/" \
  -e "$ a\UseDNS no" \
  -e "$ a\AllowUsers $newuser" /etc/ssh/sshd_config

# firewall
apt-get install ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow $newssh/tcp
ufw allow www
ufw allow https
ufw enable

ssh-keygen -A
service ssh restart

echo
echo '[quick-lemp] Ubuntu 14.04 Setup Complete'
echo 'Open a new session to confirm your settings before logging out.'

exit 0
