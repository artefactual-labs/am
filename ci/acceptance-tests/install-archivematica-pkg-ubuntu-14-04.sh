#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

# - Adaptation of "Installing Archivematica" » "Ubuntu 14.04 (Trusty) installation instructions"
# - Must be executed as root.
# - Tested using the "ubuntu-14-04-x64" droplet image.

apt-get install -y ufw
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 8000/tcp
ufw --force enable

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "mysql-server mysql-server/root_password password \"''\""
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password \"''\""
debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
debconf-set-selections <<< "archivematica-mcp-server archivematica-mcp-server/dbconfig-install boolean true"

wget -O - https://packages.archivematica.org/1.7.x/key.asc | apt-key add -
wget -O - http://jenkins-ci.archivematica.org/repos/devel.key | apt-key add -
sh -c 'echo "deb http://jenkins-ci.archivematica.org/repos/apt/release-0.11-trusty/ ./" >> /etc/apt/sources.list'
sh -c 'echo "deb http://jenkins-ci.archivematica.org/repos/apt/release-1.7-trusty/ ./" >> /etc/apt/sources.list'
sh -c 'echo "deb [arch=amd64] http://packages.archivematica.org/1.7.x/ubuntu-externals trusty main" >> /etc/apt/sources.list'

# wget -O - https://packages.archivematica.org/1.7.x/key.asc | apt-key add -
# sh -c 'echo "deb [arch=amd64] http://packages.archivematica.org/1.7.x/ubuntu trusty main" >> /etc/apt/sources.list'
# sh -c 'echo "deb [arch=amd64] http://packages.archivematica.org/1.7.x/ubuntu-externals trusty main" >> /etc/apt/sources.list'

wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
sh -c 'echo "deb http://packages.elasticsearch.org/elasticsearch/1.7/debian stable main" >> /etc/apt/sources.list'

apt-get update
apt-get upgrade -y

apt-get install -y elasticsearch
apt-get install -y archivematica-storage-service
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/storage /etc/nginx/sites-enabled/storage

curl -Ls https://bootstrap.pypa.io/get-pip.py | python - "pip==9.0.3"

apt-get install -y archivematica-mcp-server
apt-get install -y archivematica-dashboard
apt-get install -y fits
apt-get install -y archivematica-mcp-client

ln -s /etc/nginx/sites-available/dashboard.conf /etc/nginx/sites-enabled/dashboard.conf

service elasticsearch restart
update-rc.d elasticsearch defaults 95 10

wget -nv -nc -P /var/lib/clamav \
    https://github.com/artefactual-labs/clamav-files/releases/download/20180428/main.cvd \
    https://github.com/artefactual-labs/clamav-files/releases/download/20180428/daily.cvd \
    https://github.com/artefactual-labs/clamav-files/releases/download/20180428/bytecode.cvd
chown clamav:clamav /var/lib/clamav/*cvd

service clamav-freshclam restart
service clamav-daemon start
service gearman-job-server restart
service archivematica-mcp-server start
service archivematica-mcp-client start
service archivematica-storage-service start
service archivematica-dashboard start
service nginx restart
service fits start
service gearman-job-server restart
