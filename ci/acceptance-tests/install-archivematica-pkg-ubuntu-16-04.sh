#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

# - Adaptation of "Installing Archivematica" » "Ubuntu 16.04 (Xenial) installation instructions"
# - This script must be executed as root.
# - Tested using the "ubuntu-16-04-x64" droplet image.

apt-get install -y ufw
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 8000/tcp
ufw --force enable

export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password your_password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password your_password'
sudo debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
sudo debconf-set-selections <<< "archivematica-mcp-server archivematica-mcp-server/dbconfig-install boolean true"

function add_remote_apt_key() {
    sudo curl -s ${1} | sudo apt-key add -
}

function start_service() {
    sudo systemctl -q enable $1
    if $(sudo systemctl -q is-active $1) ; then
        sudo systemctl -q restart $1
    else
        sudo systemctl -q start $1
    fi
}

readonly remote_apt_keys=(
    "https://packages.archivematica.org/1.7.x/key.asc"
    "http://jenkins-ci.archivematica.org/repos/devel.key"
    "https://packages.elasticsearch.org/GPG-KEY-elasticsearch"
)

apt_repositories=(
    "deb [arch=amd64] http://packages.archivematica.org/1.7.x/ubuntu-externals xenial main"
    "deb http://packages.elasticsearch.org/elasticsearch/1.7/debian stable main"
    "deb http://jenkins-ci.archivematica.org/repos/apt/release-0.11-xenial/ ./"
    "deb http://jenkins-ci.archivematica.org/repos/apt/release-1.7-xenial/ ./"
)

readonly packages=(
    "elasticsearch"
    "archivematica-storage-service"
    "archivematica-mcp-server"
    "archivematica-dashboard"
    "archivematica-mcp-client"
)

readonly services=(
    "elasticsearch"
    "clamav-freshclam"
    "clamav-daemon"
    "fits"
    "nginx"
    "gearman-job-server"
    "archivematica-mcp-server"
    "archivematica-mcp-client"
    "archivematica-storage-service"
    "archivematica-dashboard"
)

sudo apt-get update
sudo apt-get upgrade --yes
sudo apt-get install --yes python

for item in "${remote_apt_keys[@]}"; do
    add_remote_apt_key "${item}"
done

for item in "${apt_repositories[@]}"; do
    add-apt-repository "${item}"
done

curl -s https://bootstrap.pypa.io/get-pip.py | sudo python -
sudo apt-get update
for item in "${packages[@]}"; do
    sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes ${item}
done

sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/storage /etc/nginx/sites-enabled/storage
sudo ln -sf /etc/nginx/sites-available/dashboard.conf /etc/nginx/sites-enabled/dashboard.conf
sudo systemctl reload nginx

wget -nv -nc -P /var/lib/clamav \
    https://github.com/artefactual-labs/clamav-files/releases/download/20180428/main.cvd \
    https://github.com/artefactual-labs/clamav-files/releases/download/20180428/daily.cvd \
    https://github.com/artefactual-labs/clamav-files/releases/download/20180428/bytecode.cvd
chown clamav:clamav /var/lib/clamav/*cvd

for item in "${services[@]}"; do
    start_service "${item}"
done
