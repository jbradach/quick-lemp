#!/bin/bash
#
# Quick permissions for /srv/www 
#
# GitHub:   https://github.com/jbradach/quick-lemp
#

echo 'This script will add a new www-pub group and sets permissions for/srv/www/'
read -p "${bold}Do you want to continue?[y/N]${normal} " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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
echo 'Adding www-pub'
groupadd www-pub
echo
echo 'If you want to add a user to the group, enter their username.'
read -p "Username[$SUDO_USER]: " -r newuser
if [ -z "$newuser" ]; then
  newuser=$SUDO_USER
fi
usermod -a -G www-pub $newuser

Change the ownership of everything under /var/www to root:www-pub

chown root:www-pub -R /srv/www
chmod 2775 /srv/www
find /srv/www -type d -exec chmod 2775 {} +
find /srv/www -type f -exec chmod 0664 {} +

echo 'Done! Consider changing umask to 0002.'
