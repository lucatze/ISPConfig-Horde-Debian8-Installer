# ISPConfig-Horde-Debian8-Installer
This script installs a complete webserver including ISPConfig 3.x, apache2, Dovecot and Horde Webmail on a fresh setup of Debian 8 minimal. It is intended for experts and courageous beginners. It is easy to read, easy adjustable and is based on howtoforges "The Perfect Server - Debian 8 Jessie (Apache2, BIND, Dovecot, ISPConfig 3)" by Till Brehm.

Installation:

1.  Setup your Server with Debian 8 Jessie minimal.
2.  run following commands as root
3.  rm /bin/sh
4.  cd /bin
5.  ln -s bash sh
6.  cd
7.  wget https://github.com/lucatze/ISPConfig-Horde-Debian8-Installer/archive/master.zip
8.  apt-get install -y unzip
9.  unzip master.zip
10.  cd ISPConfig-Horde-Debian8-Installer-master
11.  sh install.sh

To make things more comfortable, copy and run this entire string:

rm /bin/sh && cd /bin && ln -s bash sh && cd && wget https://github.com/lucatze/ISPConfig-Horde-Debian8-Installer/archive/master.zip && apt-get -y install unzip && unzip master.zip && cd ISPConfig-Horde-Debian8-Installer-master && sh install.sh
