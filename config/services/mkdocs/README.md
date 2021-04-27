## Development Environment

Vagrant was chosen to make development environments as close to production as possible and also to minimise differences
between operating systems. Mkcert is used to allow ssl to be valid on development system browsers (Do not use mkcert outside 
development)

1. Install Direnv - once-off

1. `cp .envrc.tpl .envrc` - once-off

1. Modify .envrc with correct values - once-off

1. `direnv allow .` - once-off, or every time .envrc is modified

1. `ansible-galaxy install -r config/ansible/requirements.yml` - each time requirements change

1. `vagrant plugin install vagrant-hosts` - once-off

1. python-netaddr required on host: `sudo dnf install python-netaddr` or `sudo apt install python-netaddr` - once-off

1. Install mkcert (jump to `build from source (requires Go 1.13+)` of [mkcert docs](https://github.com/FiloSottile/mkcert#linux)) - once-off

1. `mkcert -install` - once-off

1. `cd config/services/traefik/certs`

1. `mkcert -cert-file local.crt -key-file local.key "${DOMAIN}" "*.${DOMAIN}"` - once-off
    Note: If certs are regenerated while traefik is already up, `dc restart traefik`

1. `sudo nano /etc/hosts` and copy in block resulting from the following command:
   ```
   printf "\
   ${VAGRANT_IP} ${DOMAIN}\n\
   ${VAGRANT_IP} ${DOMAIN_TRAEFIK}\n\
   ${VAGRANT_IP} ${DOMAIN_NETDATA}\n\
   ${VAGRANT_IP} ${DOMAIN_PROMETHEUS}\n\
   ${VAGRANT_IP} ${DOMAIN_GRAFANA}\n\
   ${VAGRANT_IP} ${DOMAIN_MATOMO}\n\
   ${VAGRANT_IP} ${DOMAIN_RESOURCESPACE}\n\
   ${VAGRANT_IP} ${DOMAIN_MAILHOG}\n\
   "
   ```

1. `cd -` (or otherwise navigate to root of repo)

1. `vagrant up`

1. `vagrant ssh`

1. `cd src`

1. `direnv allow .` - each environment variable change

1. `dc up -d` - first ensure you have followed Database management steps below

1. In a browser, you can now navigate to the urls defined in /etc/hosts

## Initial database creation

1. For seperation of concerns, a new user, password and database is created for each service.
  Upon initial run:
  - `dc up -d mariadb` (wait long enough for system to become ready)
  - `config/services/mariadb/scripts/init-databases.sh`


## Seting up Services

# Wordpress

1. Backup Wordpress database and volumes, `config/services/wordpress/scripts/backup.sh`

<!-- Todo automate this more potentially -->
1. Restore MYSQL Database (to same subdomain)

   `gunzip < local/backups/wordpress/XXX.mysql.dump.sql.gzip | dc exec -T mariadb mysql -u ${MYSQL_USER_WORDPRESS} -p${MYSQL_PASSWORD_WORDPRESS} -A -D${MYSQL_DATABASE_WORDPRESS}`

1. Restore MYSQL Database (To alternate subdomain)

   Be sure to modify `old|new.domain.example` in the example command below:

   `gunzip < local/backups/wordpress/XXX.mysql.dump.sql.gzip | sed 's/old.domain.example/new.domain.example/g' | dc exec -T mariadb mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -A -D${MYSQL_DATABASE}`

1. Check Database has correct subdomain

   `dc exec mariadb mysql -u ${MYSQL_USER_WORDPRESS} -p${MYSQL_PASSWORD_WORDPRESS} ${MYSQL_DATABASE_WORDPRESS}`

   ```
   select option_value from wp_options where option_name = 'home';
   select option_value from wp_options where option_name = 'siteurl';
   ```

1. Restore wordpress volume
   `gunzip < local/backups/wordpress/XXX.wordpress.vol.tar.gzip | docker-compose run -T --rm wordpress tar -C / -xf -`

1. Modify `wp-config.php` (only if subdomain or database credentials have changed)

   `dc run --rm wordpress bash`

   ```
   apt update && apt install -f nano
   nano wp-config.php
   ```

   ```
   /** The name of the database for WordPress */
   define( 'DB_NAME', '${MYSQL_DATABASE_WORDPRESS}');

   /** MySQL database username */
   define( 'DB_USER', '${MYSQL_USER_WORDPRESS}');

   /** MySQL database password */
   define( 'DB_PASSWORD', '${MYSQL_PASSWORD_WORDPRESS}');

   ...

   define('DOMAIN_CURRENT_SITE', '${DOMAIN_WORDPRESS}');
   ```

1. Full services can now be started

   `dc up -d`

# ResourceSpace

1. Follow promps at landing page, and enter the following where applicable:
 
 - Database configuration: `See docker-compose.yml and above SQL command, it is all in there`
 - MySQL binary path: ``
 - Base URL:
   - dev: `http://resourcespace`
   - prod: `https://${DOMAIN_RESOURCESPACE}`
- ImageMagick/GraphicsMagick Path: `/usr/bin/convert`
- Ghostscript Path: `/usr/bin/ghostscript`
- FFMpeg/libav Path: `/usr/bin/ffmpeg`
- Exiftool Path: `/usr/bin/exiftool`
- AntiWord Path: `/usr/bin/antiword`
- PDFtotext Path: `/usr/bin/pdftotext`
- SMTP Settings: `See docker-compose.override.yml if on dev, else enter production SMTP server`

1. If on dev, `docker exec -it resourcespace vi /var/www/html/include/config.php` and change `$baseurl` to `https://${DOMAIN_RESOURCESPACE}`

# Provisioning NUCS

Assumptions are that the NUC will be provisioned off-site and once the work is done, planted on-site

1. Attach hard-drives, RAM and other hardware

1. Connect to monitor via HDMI, insert install media via USB (Ubuntu 20.04), connect keyboard via USB

1. Power on NUC/s and follow install prompts for Ubuntu 20.04. TODO: Advise on naming conventions (It is ok to install in offline mode if reliant on WiFi. It is easier to connect to Wifi at a later stage and update. If internet can be provided by ethernet, accept updates on initial install). Be sure to install OpenSSH server.
   Suggestions:
   - Name: `vnet-nuc-xx`
   - Server's name: `vnet-nuc-xx`
   - Username: `system`
   - Password: <autogenerate> (e.g. `pwgen 8 1`)

1. [Optional] Connect NUCS to WiFi if not already connected
   - Unfortunately it is a complicated procedure to install the required wpasupplicant package while offline. So to shortcut this, you will need to temporarily connect to the internet via ethernet (LTE for example) TODO: Provide an offline alternative
   - `sudo apt update && sudo apt install -y wpasupplicant` (now disconnect the temporary ethernet)
   - [Follow this tutorial](https://linuxconfig.org/ubuntu-20-04-connect-to-wifi-from-command-line), continue below for summary
   - `ls /sys/class/net` (e.g. wlp0s20f3)
   - `ls /etc/netplan/` (e.g. 00-installer-config.yaml)
   - `sudoedit /etc/netplan/00-installer-config.yaml` (see tutorial for content)
   - `sudo netplan apply` (add --debug flag if anything goes wrong)

1. [Optional] Generate OpenVPN client config and transport to NUC/s via USB
   - For SSH access to the OpenVPN server ask for your dev machine's public ssh key to be added to authorized keys
   - Once ssh'd in, execute: `sudo ./openvpn-install.sh` and follow prompts
   - scp .ovpn files created from server and store on USB drive
   - Modify .ovpn files with content below (just before line containing `<ca>`):
   ```
   route-nopull
   route 10.179.0.0 255.255.255.0
   route 10.2.0.0 255.255.0.0
   route 10.10.0.0 255.255.0.0
   ```

1. [Optional] Configure OpenVPN client:
   - `sudo apt update && sudo apt install -y openvpn`
   - `sudo mount /dev/sdb1 /mnt` (after inserting data USB containing client configs, `lsblk` to confirm present at `sdb1`)
   - `sudo cp /mnt/vnet-nuc-xx.ovpn /etc/openvpn/client/vnet-nuc-xx.ovpn.conf`
   - `sudo umount /mnt` (and remove USB from device)
   - `sudo chmod 0600 /etc/openvpn/client/vnet-nuc-xx.ovpn.conf`
   - `sudo chown root:root /etc/openvpn/client/vnet-nuc-xx.ovpn.conf`
   - `sudo systemctl start openvpn-client@vnet-nuc-xx.ovpn`
   - See ip with `ip a`, you should now be able to ssh in from dev machine that is also connected to the VPN, e.g. `ssh ubuntu@10.179.0.x`
   - `sudo systemctl enable openvpn-client@vnet-nuc-xx.ovpn`

1. Configure with Ansible:
   - Temporarily allow root ssh login via ssh key
     - `sudo -i`
     - `nano ~/.ssh/authorized_keys` (and copy your dev machine's public ssh key `cat ~/.ssh/id_rsa.pub`)
   - Temporarily modify `config/ansible/hosts.yml` with all the NUCs you want to provision (in parallel, so complete all above steps on each NUC first). Something like this will do, e.g:
   ```
   ungrouped:
     hosts:
       vnet-nuc-02:
         ansible_ssh_host: 10.179.0.6
         ansible_connection: ssh
       vnet-nuc-03:
         ansible_ssh_host: 10.179.0.7
         ansible_connection: ssh
   ```
   - Make sure environment variables, `ROOT_SSH_USER=root`, `PRIMARY_SSH_USER=ubuntu`
   - `./config/ansible/run.sh` (If the kernel was outdated, the playook might fail in which case just reboot each NUC and run the same again)
   - `git checkout config/ansible/hosts.yml` (store a duplicate in a safe location if preferred)