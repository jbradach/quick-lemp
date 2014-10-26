## quick-lemp
Scripts to quickly install a [LEMP Stack](https://lemp.io) (like a LAMP stack but using Nginx instead of Apache) and perform basic configuration of a new Ubuntu server.

Components include the a recent stable version of Nginx, uWSGI, and MariaDB 10.01 (drop-in replacement for MySQL).

Deploys a sample Flask app for testing.


### Scripts
__Setup__ - Basic setup for new Ubuntu server
  * Intended only for new Ubuntu installations.
  * Adds new user with sudo access and disables remote root logins.
  * Changes sshd settings to enhance security.
  * Uses UFW to apply iptables rules to limit traffic to approved ports.

__Stack__ - Installs and configures LEMP stack
  * Installs and configures Nginx, uWSGI in Emperor Mode, and MariaDB.
  * Includes virtualenv and pip.
  * MariaDB can easily be replaced with MySQL or PostgreSQL.
  * Adds a PPA to install the latest stable version Nginx.
  * Supports IPv6.
  * Optional self-signed SSL cert configuration.

### Quick Start
You should read these scripts before running them so you know what they're
doing. Changes may be necessary to meet your needs.

__Setup__ should be run as __root__ on a fresh __Ubuntu__ installation. __Stack__ should be run on a server without any existing LEMP or LAMP components.

If components are already installed, the core packages can be removed with:
```
apt-get purge apache2 nginx mysql mariadb uwsgi
apt-get autoclean
apt-get autoremove
```

#### Setup - Basic setup for new Ubuntu server:
```
wget https://raw.github.com/jbradach/quick-lemp/master/quicklemp-trusty-setup.sh
chmod +x quicklemp-trusty-setup.sh
./quicklemp-trusty-setup.sh
```

#### Stack - Installs and configures LEMP stack:
```
wget https://raw.github.com/jbradach/quick-lemp/master/quicklemp-trusty-stack.sh
chmod +x quicklemp-trusty-stack.sh
./quicklemp-trusty-stack.sh
```
