#!/bin/bash
if [ -d /etc/apache2 ]; then
	sudo rm -rf /etc/apache2/sites-enabled/vhosts.conf
	sudo ln -s /vagrant/conf/vhosts_apache.conf /etc/apache2/sites-enabled/vhosts.conf
	sudo service apache2 restart
else
	sudo rm -rf /etc/nginx/sites-available/vhosts_nginx
	sudo rm -rf /etc/nginx/sites-enabled/vhosts_nginx
	sudo cp /vagrant/conf/vhosts_nginx /etc/nginx/sites-available/vhosts_nginx
	sudo ln -s /etc/nginx/sites-available/vhosts_nginx /etc/nginx/sites-enabled/vhosts_nginx
	sudo service php7-fpm restart
	sudo service nginx restart
fi