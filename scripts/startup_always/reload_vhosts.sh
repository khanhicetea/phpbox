#!/bin/bash
sudo rm -rf /etc/apache2/sites-enabled/vhosts.conf
sudo ln -s /vagrant/conf/vhosts.conf /etc/apache2/sites-enabled/vhosts.conf
sudo service apache2 restart