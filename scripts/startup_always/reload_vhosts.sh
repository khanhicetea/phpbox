#!/bin/bash
if [ -d /etc/apache2 ]; then
	sudo rm -rf /etc/apache2/sites-enabled/vhosts.conf
	sudo ln -s /vagrant/conf/vhosts_apache.conf /etc/apache2/sites-enabled/vhosts.conf
	sudo service apache2 restart
fi
