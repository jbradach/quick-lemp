quick-lemp

[![Donate with Bitcoin](https://en.cryptobadges.io/badge/micro/15mjnqPTSphZZaBiRmrfP8jiSDzo5bYyAa)](https://en.cryptobadges.io/donate/15mjnqPTSphZZaBiRmrfP8jiSDzo5bYyAa)
[![Donate with Ethereum](https://en.cryptobadges.io/badge/micro/0xb39D022eDF05C31e1981f4F4D8137dDa9C57CFaE)](https://en.cryptobadges.io/donate/0xb39D022eDF05C31e1981f4F4D8137dDa9C57CFaE)
==========

__Update 20210406:__  This script has been neglected for way too long. If there's interest, I can update it for Ubuntu 20.04 and later.

Scripts to quickly install a LEMP Stack and perform basic configuration of new Ubuntu 12.04, 13.04, 14.04, and 15.04 servers.

Components include a recent stable version of Nginx (1.8.0) using configurations from the HTML 5 Boilerplate team, uWSGI, and MariaDB 10.0 (drop-in replacement for MySQL), PHP5, and Python.

Deploys a sample Flask app and creates a PHP page for testing.

 Scripts
--------
__Setup__ - Basic setup for new Ubuntu server.
  * Intended only for new Ubuntu installations.
  * Adds new user with sudo access and disables remote root logins.
  * Changes sshd settings to enhance security.
  * Uses UFW to apply iptables rules to limit traffic to approved ports.

__Stack__ - Installs and configures LEMP stack with support for PHP and Python applications.
  * Installs and configures Nginx and MariaDB.
  * Installs PHP-FPM for PHP5 and uWSGI in Emperor Mode for Python.
  * Includes virtualenv and pip.
  * MariaDB 10.0 can easily switched to 5.5 or substituted for PostgreSQL.
  * Adds repositories for the latest stable versions of Nginx and MariaDB..
  * Supports IPv6 by default .
  * Optional self-signed SSL cert configuration.

Quick Start
----------------
_You should read these scripts before running them so you know what they're
doing._ Changes may be necessary to meet your needs. The generic Ubuntu files are 
intended to be compatible with Ubuntu 12.04, 13.04, 14.04, and 15.04. 

__Setup__ should be run as __root__ on a fresh __Ubuntu__ installation. __Stack__ should be run on a server without any existing LEMP or LAMP components.

If components are already installed, the core packages can be removed with:
```
apt-get purge apache mysql apache2-mpm-prefork apache2-utils apache2.2-bin apache2.2-common \
libapache2-mod-php5 libapr1 libaprutil1 libdbd-mysql-perl libdbi-perl libnet-daemon-perl \
libplrpc-perl libpq5 mysql-client-5.5 mysql-common mysql-server mysql-server-5.5 php5-common \ 
php5-mysql
apt-get autoclean
apt-get autoremove
```

### Setup - Basic setup for new Ubuntu server:
#### 12.04, 13.04, 14.04, and 15.04
```
curl -LO https://raw.github.com/jbradach/quick-lemp/master/quicklemp-ubuntu-setup.sh
chmod +x quicklemp-ubuntu-setup.sh
./quicklemp-ubuntu-setup.sh
```

### Stack - Installs and configures LEMP stack:
#### 12.04, 13.04, 14.04, and 15.04
```
curl -LO https://raw.github.com/jbradach/quick-lemp/master/quicklemp-ubuntu-stack.sh
chmod +x quicklemp-ubuntu-stack.sh
./quicklemp-ubuntu-stack.sh
```
