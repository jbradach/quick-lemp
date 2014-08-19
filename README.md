## quick-lemp
Scripts to quickly install a LEMP stack with a recent stable version of Nginx, uWSGI, and MariaDB 10.1 (drop-in replacement for MySQL) on Ubuntu. The full version also provides some initial server configuration for fresh Ubuntu installs.

Deploys a sample Flask app for testing.


### Script Versions
__Core__ - Just installs the LEMP stack
  * Installs and configures Nginx, uWSGI in Emperor Mode, and MariaDB.
  * Optional self-signed SSL cert configuration.
  * Includes virtualenv and pip.
  * MariaDB can easily be replaced with MySQL or PostgreSQL.
  * Adds a PPA to install the latest stable version Nginx.

__Full__ - Configures new server and installs LEMP stack
  * Does everything in Core.
  * Intended only for new Ubuntu 14.04 installations.
  * Adds new user with sudo access and disables remote root logins.
  * Changes sshd settings to enhance security.
  * Applies iptables rules to limit traffic to approved ports.

### Quick Start
You should read these scripts before running them so you know what they're
doing. Changes may be necessary to meet your needs.

Both scripts should be run as __root__ on a fresh __Ubuntu 14.04__ installation.

#### Core - Installs and configures LEMP servers:

```
wget https://raw.github.com/jbradach/quick-lemp/master/quicklemp-trusty-core.sh
chmod +x quicklemp-trusty-core.sh
./quicklemp-trusty-core.sh
```

#### Full - New server configuration in addition to LEMP deployment:
```
wget https://raw.github.com/jbradach/quick-lemp/master/quicklemp-trusty-full.sh
chmod +x quicklemp-trusty-full.sh
./quicklemp-trusty-full.sh
```
