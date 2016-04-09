#!/usr/bin/env bash

# BEGIN : User Settings

MIRROR_COUNTRY_CODE="sg"
TIMEZONE="Asia/Ho_Chi_Minh"
MYSQL_PASSWORD=passwd
MYSQL_ADMIN_TOOL="adminer"
PHP_VERSION=7
PHP_DISPLAY_ERROR="On"
PHP_UPLOAD_MAX_SIZE="64M"
PHP_POST_MAX_SIZE="70M"
PHP_SESSION_SAVE_PATH="/tmp"
INSTALL_NODEJS=0
INSTALL_DOCKER=1

# END : User Settings

# BEGIN : Vagrant Settings

system-escape() {
  local glue
  glue=${1:--}
  while read arg; do
    echo "${arg,,}" | sed -e 's#[^[:alnum:]]\+#'"$glue"'#g' -e 's#^'"$glue"'\+\|'"$glue"'\+$##g'
  done
}

php-settings-update() {
  local args
  local settings_name
  local php_ini
  local php_extra
  args=( "$@" )
  PREVIOUS_IFS="$IFS"
  IFS='='
  args="${args[*]}"
  IFS="$PREVIOUS_IFS"
  settings_name="$( echo "$args" | system-escape )"
  for php_ini in $( sudo find /etc -type f -iname 'php*.ini' ); do
    php_extra="$( dirname "$php_ini" )/conf.d"
    sudo mkdir -p "$php_extra"
    echo "$args" | sudo tee "$php_extra/0-$settings_name.ini" >/dev/null
  done
}

# END : Vagrant Shell Scripts

# Prepare repository
sudo sed -i \
    -e "s#\w\+\.archive\.ubuntu\.com#$MIRROR_COUNTRY_CODE.archive.ubuntu.com#g" \
    -e "s#security\.ubuntu\.com#$MIRROR_COUNTRY_CODE.archive.ubuntu.com#g" \
    '/etc/apt/sources.list'

sudo apt-get install -y curl software-properties-common

# Add Docker
if [ "$INSTALL_DOCKER" -eq 1 ]; then
  sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

# Add MySQL 5.7
sudo apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 5072E1F5
echo "deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7" | sudo tee -a /etc/apt/sources.list.d/mysql.list

# Add PHP 7
sudo add-apt-repository -y ppa:ondrej/php

# Add Apache2
sudo add-apt-repository -y ppa:ondrej/apache2

# Update packages
sudo apt-get -y update

# Install system tools
sudo apt-get install -y zip vim screen zsh git

# Install MySQL 5.7
export DEBIAN_FRONTEND=noninteractive

debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''"
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $MYSQL_PASSWORD"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $MYSQL_PASSWORD"

# Install LAMP Stack
sudo apt-get install -y mysql-server

sudo apt-get install -y --force-yes php7.0-bcmath php7.0-bz2 php7.0-cli php7.0-common php7.0-curl \
                php7.0-dev php7.0-gd php7.0-gmp php7.0-imap php7.0-intl \
                php7.0-json php7.0-ldap php7.0-mbstring php7.0-mcrypt php7.0-mysql \
                php7.0-odbc php7.0-opcache php7.0-pgsql php7.0-phpdbg php7.0-pspell \
                php7.0-readline php7.0-recode php7.0-soap php7.0-sqlite3 \
                php7.0-tidy php7.0-xml php7.0-xmlrpc php7.0-xsl php7.0-zip

sudo apt-get install -y apache2 libapache2-mod-php7.0
sudo a2enmod php7.0
sudo a2enmod rewrite

# Apache & PHP Settings
php-settings-update 'date.timezone' "$TIMEZONE"
php-settings-update 'display_errors' "$PHP_DISPLAY_ERROR"
php-settings-update 'upload_max_filesize' "$PHP_UPLOAD_MAX_SIZE"
php-settings-update 'post_max_size' "$PHP_POST_MAX_SIZE"
php-settings-update 'session.save_path' "$PHP_SESSION_SAVE_PATH"

sudo sed -i 's#www-data#vagrant#' /etc/apache2/envvars
sudo sed -i 's#Directory /var/www/#Directory /vagrant/www/#' /etc/apache2/apache2.conf
sudo sed -i 's#DocumentRoot /var/www/html#DocumentRoot /vagrant/www/default#' /etc/apache2/sites-enabled/000-default.conf

sudo ln -s /vagrant/conf/vhosts_apache.conf /etc/apache2/sites-enabled/vhosts.conf

sudo service apache2 restart

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer global require hirak/prestissimo

# Install Adminer or phpMyAdmin
if [ "$MYSQL_ADMIN_TOOL" == "adminer" ] && [ "$PHP_VERSION" -eq 5 ]; then
  mkdir /vagrant/www/default/adminer
  rm -f /vagrant/www/default/adminer/index.php
  wget https://www.adminer.org/latest-mysql-en.php -O /vagrant/www/default/adminer/index.php
else
  wget https://files.phpmyadmin.net/phpMyAdmin/4.6.0/phpMyAdmin-4.6.0-english.tar.gz -O phpmyadmin.tar.gz
  tar -xf phpmyadmin.tar.gz
  rm -f phpmyadmin.tar.gz
  rm -rf /vagrant/www/default/phpmyadmin
  mv phpMyAdmin-4.6.0-english /vagrant/www/default/phpmyadmin
  cp /vagrant/www/default/phpmyadmin/config.sample.inc.php /vagrant/www/default/phpmyadmin/config.inc.php
fi

# Install Docker
if [ "$INSTALL_DOCKER" -eq 1 ]; then
  sudo apt-get purge -y lxc-docker
  sudo apt-get install -y linux-image-extra-$(uname -r)
  sudo apt-get install -y docker-engine
  sudo service docker restart; true
  sudo usermod -aG docker vagrant
  sudo sed -i 's#DEFAULT_FORWARD_POLICY="DROP"#DEFAULT_FORWARD_POLICY="ACCEPT"#' /etc/default/ufw
  sudo ufw reload; true
  sudo ufw allow 2375/tcp; true
fi

# Install NodeJS based on NodeSource (This command will run apt-get update)
if [ "$INSTALL_NODEJS" -eq 1 ]; then
    curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
    sudo apt-get install -y nodejs    
fi

exit 0
