## quick-lemp
Scripts to quickly install a LEMP stack with Nginx, uWSGI, and MariaDB on Ubuntu.

Deploys a sample Flask app to help get you started.

### Scripts
__Core__ - Just installs the LEMP stack
  * Installs and configures Nginx, uWSGI in Emperor Mode, and MariaDB.
  * Includes virtualenv and pip.
  * MariaDB can easily be replaced with MySQL or PostgreSQL.

__Full__ - Configures new server and installs LEMP stack
  * Intended only for new Ubuntu 12.04 installations.
  * Adds new user with sudo access and disables remote root logins.
  * Changes sshd settings to enhance security.
  * Applies iptables rules to limit traffic to approved ports.

### Quick Start
You should read these scripts before running them so you know what they're
doing. Changes may be necessary to meet your needs.

Both scripts should be run as root on a fresh Ubuntu 12.04 installation.
