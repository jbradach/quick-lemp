#!/bin/bash
echo '[LEMP Server Setup - Full]'
echo 'Performs basic initial setup for fresh Ubuntu 12.04 installation.'
echo 'Installs Nginx, MariaDB, and uWSGI and deploys a small Flask app.'
echo
read -p 'Do you want to continue? ' -n 1 -r
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
read -p 'Username: ' -r NEWUSER
read -p 'Password: ' -r NEWPASS
useradd $NEWUSER -s /bin/bash -m
echo "$NEWUSER:$NEWPASS" | chpasswd
usermod -a -G sudo $NEWUSER
usermod -a -G www-data $NEWUSER

# sshd
echo -e '\n[Configuring sshd and iptables]'
read -p 'New SSH Port: ' -i '22'-r NEWSSH
sed -i.bak -e "s/^Port 22/Port $NEWSSH/" \
  -e "s/^PermitRootLogin yes/PermitRootLogin no/" \
  -e "$ a\UseDNS no" \
  -e "$ a\AllowUsers $NEWUSER" /etc/ssh/sshd_config

# iptables
echo "*filter
-A INPUT -i lo -j ACCEPT
-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT
-A INPUT -p tcp --dport 5000 -j ACCEPT
-A INPUT -p tcp --dport 8000 -j ACCEPT
-A INPUT -p tcp -m state --state NEW --dport $NEWSSH -j ACCEPT
-A INPUT -m limit --limit 5/min -j LOG --log-prefix \"iptables denied: \" --log-level 7
-A INPUT -j DROP
-A FORWARD -j DROP
COMMIT" > /etc/iptables.rules
iptables-restore < /etc/iptables.rules
echo '#!/bin/sh
iptables-restore < /etc/iptables.rules
exit 0' > /etc/network/if-pre-up.d/iptablesload
chmod +x /etc/network/if-pre-up.d/iptablesload
echo '#!/bin/sh
iptables-save -c > /etc/iptables.rules
exit 0' > /etc/network/if-post-down.d/iptasave
chmod +x /etc/network/if-post-down.d/iptasave

# Update packages and add MariaDB repository
echo -e '\n[Package Updates]'
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository 'deb http://ftp.osuosl.org/pub/mariadb/repo/10.0/ubuntu precise main'
apt-get update
apt-get -y upgrade

# Depencies and pip
echo -e '\n[Dependencies]'
apt-get -y install build-essential debconf-utils python-dev libpcre3-dev libssl-dev python-pip

# Nginx
echo -e '\n[Nginx]'
apt-get -y install nginx
rm /etc/nginx/sites-enabled/default
echo 'server {
    listen 80;
    server_name $hostname;

    location /static {
        alias /srv/www/flaskapp/app/static;
    }

    location / { try_files $uri @flaskapp; }
    location @flaskapp {
        include uwsgi_params;
        uwsgi_pass unix:/tmp/flaskapp.sock;
        }
    }' > /etc/nginx/sites-available/flaskapp
mkdir -p /srv/www/flaskapp/app/static
mkdir -p /srv/www/flaskapp/app/templates
ln -s /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/flaskapp

# uWSGI
echo -e '\n[uWSGI]'
pip install uwsgi
mkdir /etc/uwsgi
mkdir /var/log/uwsgi
echo 'description "uWSGI Emperor"
start on runlevel [2345]
stop on runlevel [06]
exec uwsgi --die-on-term --emperor /etc/uwsgi --logto /var/log/uwsgi/uwsgi.log' > /etc/init/uwsgi-emperor.conf
echo '[uwsgi]
chdir = /srv/www/flaskapp
logto = /var/log/uwsgi/flaskapp.log
virtualenv = /srv/www/flaskapp/venv
socket = /tmp/flaskapp.sock
uid = www-data
gid = www-data
master = true
wsgi-file = wsgi.py
callable = app
vacuum = true' > /etc/uwsgi/flaskapp.ini
tee -a /srv/www/flaskapp/wsgi.py > /dev/null <<EOF
from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return "It works!"
EOF

# virtualenv
echo -e '\n[virtualenv]'
pip install virtualenv
cd /srv/www/flaskapp
virtualenv venv
source venv/bin/activate
pip install flask
deactivate

# Permissions
echo -e '\n[Adjusting Permissions]'
chown -R $NEWUSER:www-data /srv/www/*
chmod -R g+rw /srv/www/*
sh -c 'find /srv/www/* -type d -print0 | sudo xargs -0 chmod g+s'

# MariaDB
echo -e '\n[MariaDB]'
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y install mariadb-server
echo 'The find_mysql_client error can be ignored.'
mysql_secure_installation
service ssh restart
start uwsgi-emperor
service nginx restart
echo '[LEMP Setup Complete]'
echo 'Open a new session to confirm your settings before logging out.'
exit 0
