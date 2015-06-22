#!/bin/bash
#
# [Quick LEMP Server Setup Script]
#
# GitHub:   https://github.com/jbradach/quick-lemp
# Author:   James Bradach
# URL:      https://jamesbradach.com
#
bold=$(tput bold)
normal=$(tput sgr0)
cat <<!

${bold}[quick-lemp] Server Setup${normal}

Configured and tested for Ubuntu 12.04, 13.04, 14.04, and 15.04.
Performs very basic initial steps for a fresh Ubuntu installation.
More info at ${bold}https://github.com/jbradach/quick-lemp${normal}

!
read -p "${bold}Do you want to continue?[y/N]${normal} " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo 'Exiting...'
  exit 1
fi
echo
echo
echo 'Checking distribution ...'
if [ ! -x  /usr/bin/lsb_release ]; then
  echo 'You do not appear to be running Ubuntu.'
  echo 'Exiting...'
  exit 1
fi
echo "$(lsb_release -a)"
echo
dis="$(lsb_release -is)"
rel="$(lsb_release -rs)"
if [[ "${dis}" != "Ubuntu" ]]; then
  echo "${dis}: You do not appear to be running Ubuntu"
  echo 'Exiting...'
  exit 1
elif [[ ! "${rel}" =~ ("12.04"|"13.04"|"14.04"|"15.04") ]]; then #
  echo "${bold}${rel}:${normal} You do not appear to be running a supported Ubuntu release."
  echo 'Exiting...'
  exit 1
fi
echo 'Checking permissions...'
echo
if [[ $EUID -ne 0 ]]; then
  echo 'This script must be run with root privileges.' 1>&2
  echo 'Exiting...'
  exit 1
fi

# Color Prompt
echo -e '\n[Bash Settings for Color]'
sed -i.bak -e 's/^#force_color/force_color/' \
 -e 's/1;34m/1;35m/g' \
 -e "\$aLS_COLORS=\$LS_COLORS:'di=0;35:' ; export LS_COLORS" /etc/skel/.bashrc

# Users
echo -e '\n[Create New User]'
echo -e 'If this field is left blank, the default account listed will be updated.'
read -p "Username[$SUDO_USER]: " -r newuser
if [ -z "$newuser" ]; then
  newuser=$SUDO_USER
fi
egrep "^$newuser" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
  echo "$newuser exists, skipping ahead..."
else
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
fi
usermod -a -G sudo $newuser
usermod -a -G www-data $newuser

newssh=22

# sshd
if [ -f /etc/ssh/sshd_config ]; then
    echo -e '\n[Configuring sshd and iptables]'
    read -p 'New SSH Port: ' -i '22'-r newssh
    sed -i.bak -e "s/^Port 22/Port $newssh/" \
      -e "s/^PermitRootLogin yes/PermitRootLogin no/" \
      -e "$ a\UseDNS no" \
      -e "$ a\AllowUsers $newuser" /etc/ssh/sshd_config
else
    echo "/etc/ssh/sshd_config does not exist, skipping ahead..."
fi

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
echo "${bold}[quick-lemp] Ubuntu Server Setup Complete${normal}"
echo 'Open a new session to confirm your settings before logging out.'

exit 0
