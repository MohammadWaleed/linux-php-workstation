#!/bin/sh

echo "Preparing WorkStation This may take a while"

# brew Requirements
sudo apt-get install build-essential curl file git 

# codium (VSCode without microsoft telemetry)
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo apt-key add -
echo 'deb https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/repos/debs/ vscodium main' | sudo tee --append /etc/apt/sources.list.d/vscodium.list
sudo apt-get update
sudo apt-get install codium

# brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brewBasePath="/home/linuxbrew/.linuxbrew"
brewPath="$brewBasePath/bin/brew"

echo "eval \$($brewPath shellenv)" >>~/.profile

# php
$brewPath install php

# composer
$brewPath install composer

# apache2
$brewPath install apache2

# mysql
$brewPath install mysql

# redis
$brewPath install redis

# nodejs
$brewPath install node

# xdebug
$brewBasePath/bin/pecl install xdebug

# composer
$brewPath install composer


# configure php in apache


httpdConf="$brewBasePath/etc/httpd/httpd.conf"

echo "
LoadModule php7_module $brewBasePath/opt/php/lib/httpd/modules/libphp7.so

<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>

ServerName localhost
" >> $httpdConf

# enable rewrite module
sed -i 's%#LoadModule rewrite_module lib/httpd/modules/mod_rewrite.so%LoadModule rewrite_module lib/httpd/modules/mod_rewrite.so%' $httpdConf 

# update user and group to www-data
sed -i 's/_www/www-data/' $httpdConf


apacheDocumentRoot=~/public_html

# update document root
sed -i "s%DocumentRoot \"/home/linuxbrew/.linuxbrew/var/www\"%DocumentRoot \"$apacheDocumentRoot/www\"%" $httpdConf
sed -i "s%<Directory \"/home/linuxbrew/.linuxbrew/var/www\">%<Directory \"$apacheDocumentRoot/www\">%" $httpdConf

# Allow override in your document root to allow beautiful links and whatever your .htaccess file have
sed -i '266s/None/All/' $httpdConf

sed -i '266 a\ \n\tDirectoryIndex index.php index.html' $httpdConf

mkdir $apacheDocumentRoot
mkdir $apacheDocumentRoot/www
# mkdir $apacheDocumentRoot/log
# mkdir $apacheDocumentRoot/log/httpd
# mkdir $apacheDocumentRoot/log/httpd/error_log
# mkdir $apacheDocumentRoot/log/httpd/access_log

chmod 755 -R $apacheDocumentRoot


#configure XDebug
phpIniPath=$($brewBasePath/bin/php --ini | grep /php.ini | cut -d":" -f2)

sed -i "1i  [xdebug]" $phpIniPath
sed -i "1a  zend_extension=\"xdebug.so\"" $phpIniPath
sed -i "1a  xdebug.remote_enable=on" $phpIniPath
sed -i "1a  xdebug.remote_handler=dbg" $phpIniPath
sed -i "1a  xdebug.remote_mode=req" $phpIniPath
sed -i "1a  xdebug.remote_host=localhost" $phpIniPath
sed -i "1a  xdebug.remote_port=9000" $phpIniPath
sed -i "1a  xdebug.remote_autostart=1" $phpIniPath


# add autostart for apache mysql and redis
cronTab=$(crontab -l)

cronTab=$cronTab"
@reboot apachectl start
@reboot mysql.server start
@reboot nohup redis-server > /dev/null 2>&1 &
";

echo $cronTab | crontab -


# install laravel 
$brewBasePath/bin/composer global require laravel/installer

echo "
To start the services:
Apache:
apachectl start

Mysql:
mysql.server start

Redis:
redis-server start
or to start in the background as it should be
nohup redis-server > /dev/null 2>&1 &
"
