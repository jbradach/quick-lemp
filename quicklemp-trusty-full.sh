#!/bin/bash
echo '[LEMP Server Setup - Full]'
echo 'Performs basic initial setup for fresh Ubuntu 14.04 installation.'
echo 'Installs Nginx, MariaDB, and uWSGI and deploys a small Flask app.'
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
-A INPUT -p tcp -m state --state NEW --dport $newssh -j ACCEPT
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
add-apt-repository 'deb http://ftp.utexas.edu/mariadb/repo/10.1/ubuntu trusty main'
add-apt-repository ppa:nginx/stable
apt-get update
apt-get -y upgrade

# Depencies and pip
echo -e '\n[Dependencies]'
apt-get -y install build-essential debconf-utils python-dev libpcre3-dev libssl-dev python-pip

# Nginx
echo -e '\n[Nginx]'
apt-get -y install nginx
rm /etc/nginx/sites-enabled/default
echo 'upstream uwsgi_host {
  server unix:/tmp/flaskapp.sock;
}

server {
  listen 80 default_server;
  listen [::]:80 default_server ipv6only=on;

  location ^~ /static/ {
      alias /srv/www/flaskapp/app/static;
  }

  location / { try_files $uri @flaskapp; }
  location @flaskapp {
      include uwsgi_params;
      uwsgi_pass uwsgi_host;
  }
}' > /etc/nginx/sites-available/flaskapp
echo
read -p 'Do you want to create a self-signed SSL cert and configure HTTPS? [y/N] ' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/default_ssl.key -out /etc/nginx/default_ssl.crt
  chmod 400 /etc/nginx/default_ssl.key

  echo 'server {
listen 443 default_server;
listen [::]:443 default_server ipv6only=on;

ssl on;
ssl_certificate /etc/nginx/default_ssl.crt;
ssl_certificate_key /etc/nginx/default_ssl.key;

ssl_session_timeout 5m;

ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers "HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";
ssl_prefer_server_ciphers on;

location ^~ /static/ {
    alias /srv/www/flaskapp/app/static;
}

location / { try_files $uri @flaskapp; }
location @flaskapp {
    include uwsgi_params;
    uwsgi_pass uwsgi_host;
    }
}' >> /etc/nginx/sites-available/flaskapp
fi
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
chdir = /srv/www/%n
logto = /var/log/uwsgi/%n.log
virtualenv = /srv/www/%n/venv
socket = /tmp/%n.sock
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
chown -R $newuser:www-data /srv/www/*
chmod -R g+rw /srv/www/*
sh -c 'find /srv/www/* -type d -print0 | sudo xargs -0 chmod g+s'

# MariaDB
echo -e '\n[MariaDB]'
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y install mariadb-server
echo
echo 'The find_mysql_client error can be ignored.'
echo
mysql_secure_installation
service ssh restart
start uwsgi-emperor
service nginx restart
echo
echo '[LEMP Setup Complete]'
echo 'Open a new session to confirm your settings before logging out.'

exit 0
