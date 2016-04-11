#!/bin/bash
# v0.1 - 11.04.2016 (DD/MM/YY)
# Author: Luca Oltenau (luca.oltenau@gmail.com)
# To do: Make package with jailkit.txt, pureftpd.txt, dovecot-pop3imap.txt.
# To do: Change dash to bash and call this script.
# To do: letsencrypt integration, add nice colors, try to automatize more, nicer descriptions, embed tutorial video, SSL for Horde, VHost example.
# To do: replace bastille firewall with ufw
# Based on Till Brehm's "The Perfect Server - Debian 8 Jessie (Apache2, BIND, Dovecot, ISPConfig 3)"
# https://www.howtoforge.com/tutorial/perfect-server-debian-8-jessie-apache-bind-dovecot-ispconfig-3/
# mysql code in line 364-370 by omeinusch. https://gist.github.com/omeinusch/6397770 Thank you.
#
# In comparison to the howtoforge approach i changed following things:
# No Roundcube, no SquirrelMail, no Mailman, no SuPHP. Everything else is included.

#####################
# Development files #
#####################

# These files should be included in master.zip on GitHub
echo
echo "Downloading some config files."
echo
cd ISPConfig-Horde-Debian8-Installer-master
wget -q https://www.puca.biz/isp/dovecot-pop3imap.txt
wget -q https://www.puca.biz/isp/jailkit.txt
wget -q https://www.puca.biz/isp/pureftpd.txt

##########################################
# Introduction and Hostname manipulation #
##########################################
clear
echo "v0.1 - 11.04.2016 (DD/MM/YY)"
echo
echo "==================================================================="
echo "Welcome to another semi-automatic Debian 8 Setup Script"
echo "including ISPConfig and Horde Webmail"
echo "==================================================================="
echo
echo
echo "This script assumes a minimal and fresh installation of Debian 8 Jessie. Are you ready?"
echo
echo
read -p "=== Yes! (Press Enter) ==="
echo
echo
echo
echo -e "Please enter your Hostname (example.exampleserver.com) "
echo
read hostname		# User Input Hostname
echo
echo

subdomain=$(echo "$hostname" | cut -f1 -d".")		# Edit entered hostname to obtain subdomain and set variable "subdomain". Removing everything until first . dot.


ip="$(ifconfig | grep -v 'eth0:' | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"		# add system IP to variable $ip

echo $ip	$hostname	$subdomain >> /etc/hosts		# add entry to /etc/hosts

> /etc/hostname							# clear /etc/hostname

echo $subdomain >> /etc/hostname		# add subdomain to /etc/hostname

########################
# Editing sources.list #
########################
cp /etc/apt/sources.list /etc/apt/sources.list.bak	# Doing backup of sources.list. You never know.
rm /etc/apt/sources.list				# removing sources.list in order to update it with new one

echo -e "deb http://ftp.us.debian.org/debian/ jessie main contrib non-free\ndeb-src http://ftp.us.debian.org/debian/ jessie main contrib non-free\ndeb http://security.debian.org/ jessie/updates main contrib non-free\ndeb-src http://security.debian.org/ jessie/updates main contrib non-free" >> /etc/apt/sources.list	# creating new sources.list
chmod 644 /etc/apt/sources.list		# chmod sources.list to old value
apt-get update						# updating packages
apt-get upgrade	-y					# upgrading packages

##########################
# Installing some basics #
##########################

apt-get install -y unzip zip nano ntp ntpdate git pgpgpg ssh openssh-server rar unrar ntp ntpdate	# installing bunch of basics
clear
echo
echo
echo "======================================================================================================"
echo "Answer the next prompt with >Internet Site<. After you will be asked to choose a password for MariaDB."
echo "======================================================================================================"
echo
echo
read -p "=== Continue (Enter) ==="
echo
echo
echo -e "WRITE DOWN THE MariaDB ROOT PASSWORD, YOU ARE GOING TO CHOOSE. We will need it later ;)"
echo
read -p "=== Got it (Enter) ==="
echo
echo

####################################
# Installing mail apps and MariaDB #
####################################

apt-get install -y postfix postfix-mysql postfix-doc mariadb-client mariadb-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd sudo #	install bunch of stuff.

######################################
# Configuring /etc/postfix/master.cf #
######################################

sed -i "s/#submission/submission/g" /etc/postfix/master.cf 																	# editing /etc/postfix/master.cf
sed -i "s/#  -o syslog_name=postfix/  -o syslog_name=postfix/g" /etc/postfix/master.cf 										# editing /etc/postfix/master.cf
sed -i "s/#  -o smtpd_tls_security_level=encrypt/  -o smtpd_tls_security_level=encrypt/g" /etc/postfix/master.cf 			# editing /etc/postfix/master.cf
sed -i "s/#  -o smtpd_sasl_auth_enable=yes/  -o smtpd_sasl_auth_enable=yes/g" /etc/postfix/master.cf 						# editing /etc/postfix/master.cf
sed -i "s/#  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject/  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject/g" /etc/postfix/master.cf 						# editing /etc/postfix/master.cf
sed -i "s/#smtps     inet  n/smtps     inet  n/g" /etc/postfix/master.cf 													# editing /etc/postfix/master.cf
sed -i "s/#  -o syslog_name=postfix\/smtps/  -o syslog_name=postfix\/smtps/g" /etc/postfix/master.cf 							# editing /etc/postfix/master.cf
sed -i "s/#  -o smtpd_tls_wrappermode=yes/  -o smtpd_tls_wrappermode=yes/g" /etc/postfix/master.cf 							# editing /etc/postfix/master.cf
service postfix restart

##############################################################################
# Installing Amavisd-new, SpamAssassin And Clamav and configuring clamd.conf #
##############################################################################

apt-get install -y amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl	# install bunch of stuff


sed -i "s/AllowSupplementaryGroups false/AllowSupplementaryGroups true/g" /etc/clamav/clamd.conf		# editing clamd.conf
service spamassassin stop
systemctl disable spamassassin

#########################################################################
# Installing Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt  #
#########################################################################
clear
echo
echo "======================================================================================================"
echo "You will be asked for several options. Answer as following:"
echo -e "(take a picture of this... might take some time till we get there ;)"
echo
echo "	Web server to reconfigure automatically: <- apache2"
echo "	Configure database for phpmyadmin with dbconfig-common? <- yes"
echo "	Enter the password of the administrative user? <- MariaDB root password"
echo "	Enter the phpmyadmin application password? <-  Simply press enter"
echo "======================================================================================================"
echo
echo
read -p "=== Continue (Enter) ==="
echo
echo

apt-get install -y apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached libapache2-mod-passenger	# installing just another bunch of software

a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest cgi
service apache2 restart

##################################
# Installing XCache and PHP-FPM  #
##################################

apt-get install -y php5-xcache
service apache2 -y restart
apt-get install -y libapache2-mod-fastcgi php5-fpm

a2enmod actions fastcgi alias
service apache2 restart

###############################
# Install PureFTPd And Quota  #
###############################

apt-get install -y pure-ftpd-common pure-ftpd-mysql quota quotatool
sed -i "s/VIRTUALCHROOT=false/VIRTUALCHROOT=true/g" /etc/default/pure-ftpd-common		# editing pure-ftpd-common
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/
clear
echo
echo "======================================================================================================"
echo "We are going to generate a SSL Certificate for PureFTPd. Simply answer the upcoming options according"
echo "to your taste."
echo
echo
echo "=== NOTE ==="
echo "Country code must be TWO digits only!"
echo "======================================================================================================"
echo
echo
read -p "=== Continue (Enter) ==="
echo
echo
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
service pure-ftpd-mysql restart

###################################
# Asking user to configure fstab  #
###################################

clear
echo
echo "======================================================================================================"
echo "		Editing /etc/fstab to enable quota"
echo "======================================================================================================"
echo
echo "Please read the following instructions carefully. After reading it, nano will open /etc/fstab and you have to"
echo "do some edits."
echo
echo
read -p "=== Got it (Enter) ==="
echo
clear
echo
echo
echo -e "Add -> ,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0"
echo
echo "right after -> errors=remount-ro. Make sure to keep the spaces or tab after vfsv0"
echo "In case there is no errors=remount-ro, you need to add the string with a space or tab after ext4."
echo "Keep everything after vfsv0."
echo
echo "Example:"
echo
echo -e "# /etc/fstab: static file system information."
echo -e "#"
echo -e "# Use 'blkid' to print the universally unique identifier for a"
echo -e "# device; this may be used with UUID= as a more robust way to name devices"
echo -e "# that works even if disks are added and removed. See fstab(5)."
echo -e "#"
echo -e "# <file system> <mount point>   <type>  <options>       <dump>  <pass>"
echo -e "# / was on /dev/vda1 during installation"
echo -e "UUID=afb7272d-6c75-4f4c-adca-7f755b913a0c /               ext4    errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0 0       1"
echo -e "# swap was on /dev/vda2 during installation"
echo -e "UUID=961a1e6b-5875-491a-a25b-522da9abc841 none            swap    sw              0       0"
echo -e "/dev/sr0        /media/cdrom0   udf,iso9660 user,noauto     0       0"
echo
echo
echo
echo "		Watch this short video for additional help http://not-ready-yet"
echo
echo "======================================================================================================"
echo
echo
read -p "=== Continue (Enter) ==="
clear


nano /etc/fstab
clear
mount -o remount /
quotacheck -avugm
quotaon -avug

##################################################################
# Installing BIND DNS Server and Vlogger, Webalizer, And AWStats #
##################################################################

apt-get install -y bind9 dnsutils
apt-get install -y vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl

sed 's/^/#/' /etc/cron.d/awstats		# edit awstats and comment everything out

########################
# Jailkit Installation #
########################

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.17.tar.gz
tar xvfz jailkit-2.17.tar.gz
cd jailkit-2.17
./debian/rules binary
cd ..
dpkg -i jailkit_2.17-1_*.deb
rm -rf jailkit-2.17*

#########################
# fail2ban Installation #
#########################

apt-get install -y fail2ban

cat ~/ISPConfig-Horde-Debian8-Installer-master/jailkit.txt >> /etc/fail2ban/jail.local		# create jail.local and insert data from jailkit.txt
cat ~/ISPConfig-Horde-Debian8-Installer-master/pureftpd.txt >> /etc/fail2ban/filter.d/pureftpd.conf	# create pureftpd.conf and insert data from pureftpd.txt
cat ~/ISPConfig-Horde-Debian8-Installer-master/dovecot-pop3imap.txt >> /etc/fail2ban/filter.d/dovecot-pop3imap.conf	# create dovecot-pop3imap.txt and insert data from dovecot-pop3imap.txt

echo "ignoreregex =" >> /etc/fail2ban/filter.d/postfix-sasl.conf
service fail2ban restart

##########################
# ISPConfig Installation #
##########################

cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/
clear
echo
echo "==================================================================="
echo "In case there is any failure or you do wrong settings, simply type:"
echo
echo "php -q /tmp/ispconfig3_install/install/install.php"
echo
echo "and restart installation of ISPConfig"
echo "Remember: Countrycode has only two digits!"
echo "==================================================================="
echo
read -p "=== Continue (Enter) ==="
php -q install.php

###############
# Horde Notes #
###############

clear
echo
echo "================================================================"
echo "We are almost done. Please login to your ISPConfig Account using"
echo "================================================================"
echo
echo "https://$hostname:8080"
echo
echo "User: admin"
echo "Password: admin"
echo
echo "================================================================"
echo "Let's create a admin mailbox for horde."
echo "================================================================"
echo
echo "The steps are:"
echo
echo "Email -> Domain -> Add new Domain -> example.com -> Save"
echo "Email Mailbox -> Add new Mailbox -> Fill in Alias and choose Domain -> Save"
echo
echo "Press Enter when you created the mailbox."
echo
echo "================================================================"
echo
read -p "=== Continue (Enter) ==="
clear
echo
echo "The Horde installer will ask you for a installation path."
echo "Just type /var/www/html/horde"
echo 
read -p "=== Continue (Enter) ==="
echo

######################
# Horde Installation #
######################

mkdir /var/www/html/horde
pear channel-discover pear.horde.org
pear install horde/horde_role
pear run-scripts horde/horde_role
clear
echo
echo "================================================="
echo "Go and grab a coffe. This will take some time."
echo "There will be some warnings. You can ignore them."
echo "There won't be any message for several minutes."
echo "================================================="
echo
pear install -a -B horde/webmail
chown -R www-data:www-data /var/www/html/horde
clear
echo
echo "Please enter your previously chosen MariaDB root password:"
echo
read PASS
echo
echo
echo "Please choose a password for the MariaDB Horde user:"
echo "Please write it down. We will need it later."
echo
read MARIAPASS
mysql -uroot -p$PASS <<MYSQL_SCRIPT
CREATE DATABASE horde;
CREATE USER 'horde'@'localhost' IDENTIFIED BY '$MARIAPASS';
GRANT ALL PRIVILEGES ON horde.* TO 'horde'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
echo
echo
echo "==================================================================="
echo "Horde Installation"
echo "==================================================================="
echo
echo "Answer the following prompts like this:"
echo
echo "What database backend should we use?-------------------> mysql"
echo "Username to connect to the database as-----------------> horde"
echo "Password to connect with-------------------------------> MariaDB Horde password"
echo "How should we connect to the database------------------> tcp"
echo "Database server/host?----------------------------------> localhost"
echo "Port the DB is running on, if non-standard [3306]------> Press Enter"
echo "Database name to use-----------------------------------> horde"
echo "Internally used charset [utf-8]------------------------> Press Enter"
echo "Type your choice [0]-----------------------------------> Press Enter"
echo "Certification Authority to use for SSL connections-----> Press Enter"
echo "Type your choice [false]-------------------------------> Press Enter"
echo "=================================================================="
echo
read -p "=== Continue (Enter) ==="
echo
echo "In case the installation stucks, just quit terminal window, login"
echo "again and run the command   webmail-install   as root."
echo "Horde will be accessible under http://$hostname/horde"
echo
read -p "=== Continue (Enter) ==="
echo
webmail-install
clear
echo "==================================================================="
echo "		FINISHED"
echo "==================================================================="
echo
echo "Horde:"
echo "http://$hostname/horde"
echo "Horde User: the email you specified"
echo "Horde Password: the mailbox password!"
echo
echo "ISPConfig:"
echo "https://$hostname:8080"
echo "User: admin"
echo "Password: admin"
echo
echo 
echo "Enjoy your freshly installed system."
echo "==================================================================="
