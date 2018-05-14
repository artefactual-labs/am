#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

# - This script must be executed as root.
# - Tested using the "centos-7-x64" droplet image.

function get_env_boolean() {
    local name="$1"
    local default="$2"
    local ret="${default}"
    if [ "${default}" == "true" ]; then
        if [ "${!name}" == "no" ] || [ "${!name}" == "false" ] || [ "${!name}" == "0" ]; then
            ret="false"
        fi
    fi
    if [ "${default}" == "false" ]; then
        if [ "${!name}" == "yes" ] || [ "${!name}" == "true" ] || [ "${!name}" == "1" ]; then
            ret="true"
        fi
    fi
    echo -n "${ret}"
}

search_enabled=$(get_env_boolean "SEARCH_ENABLED" "true")
local_repository=$(get_env_boolean "LOCAL_REPOSITORY" "false")

echo "~~~~~~~~ DEBUG ~~~~~~~~~~~~~~~~~~~~~~~~~~~"
while read -r line; do echo "$line=${!line}"; done < <(compgen -v | grep -v '[^[:lower:]_]' | grep -v '^_$')
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


#
# Configure repository
#

if [ "${local_repository}" == "true" ] ; then
    bash -c 'cat << EOF > /etc/yum.repos.d/archivematica.repo
[archivematica]
name=archivematica
baseurl=file:///am-packbuild/rpm/_yum_repository/
enabled=1
gpgcheck=0
EOF'
else
    bash -c 'cat << EOF > /etc/yum.repos.d/archivematica.repo

# [archivematica]
# name=archivematica
# baseurl=https://packages.archivematica.org/1.7.x/centos
# gpgcheck=1
# gpgkey=https://packages.archivematica.org/1.7.x/key.asc
# enabled=1

[archivematica]
name=archivematica
baseurl=http://jenkins-ci.archivematica.org/repos/rpm/release-1.7/
gpgcheck=0
enabled=1

[archivematica-storage-service]
name=archivematica-storage-service
baseurl=http://jenkins-ci.archivematica.org/repos/rpm/release-0.11/
gpgcheck=0
enabled=1

EOF'
fi

bash -c 'cat << EOF >> /etc/yum.repos.d/archivematica.repo
[archivematica-extras]
name=archivematica-extras
baseurl=https://packages.archivematica.org/1.7.x/centos-extras
gpgcheck=1
gpgkey=https://packages.archivematica.org/1.7.x/key.asc
enabled=1
EOF'

yum update -y
yum install -y epel-release policycoreutils-python


#
# SELinux tweaks
#

if [ $(getenforce) != "Disabled" ]; then
    semanage port -m -t http_port_t -p tcp 81
    semanage port -a -t http_port_t -p tcp 8001
    setsebool -P httpd_can_network_connect_db=1
    setsebool -P httpd_can_network_connect=1
    setsebool -P httpd_setrlimit 1
fi


#
# Set up the firewall
#

yum --assumeyes install firewalld
systemctl restart dbus
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=81/tcp
firewall-cmd --permanent --add-port=8001/tcp
firewall-cmd --permanent --list-all
firewall-cmd --reload

#
# Install MariaDB and Gearman
#

yum install -y mariadb-server gearmand
systemctl enable mariadb
systemctl start mariadb
systemctl enable gearmand
systemctl start gearmand


if [ "${search_enabled}" == "true" ] ; then
    rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
    bash -c 'cat << EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-1.7]
name=Elasticsearch repository for 1.7 packages
baseurl=https://packages.elastic.co/elasticsearch/1.7/centos
gpgcheck=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
EOF'
    yum install -y java-1.8.0-openjdk-headless elasticsearch
    systemctl enable elasticsearch
    systemctl start elasticsearch
fi

#
# Archivematica Storage Service
#

yum install -y python-pip archivematica-storage-service
sudo -u archivematica bash -c " \
  set -a -e -x
  source /etc/sysconfig/archivematica-storage-service
  cd /usr/lib/archivematica/storage-service
  /usr/share/archivematica/virtualenvs/archivematica-storage-service/bin/python manage.py migrate
";

systemctl enable archivematica-storage-service
systemctl start archivematica-storage-service
systemctl enable nginx
systemctl start nginx
systemctl enable rngd
systemctl start rngd


#
# Dashboard and MCPServer
#

yum install -y archivematica-common archivematica-mcp-server archivematica-dashboard

mysql -hlocalhost -uroot -e "DROP DATABASE IF EXISTS MCP; CREATE DATABASE MCP CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -hlocalhost -uroot -e "CREATE USER 'archivematica'@'localhost' IDENTIFIED BY 'demo';"
mysql -hlocalhost -uroot -e "GRANT ALL ON MCP.* TO 'archivematica'@'localhost';"

sudo -u archivematica bash -c " \
  set -a -e -x
  source /etc/sysconfig/archivematica-dashboard
  cd /usr/share/archivematica/dashboard
  /usr/share/archivematica/virtualenvs/archivematica-dashboard/bin/python manage.py migrate --noinput
";

sh -c 'echo "ARCHIVEMATICA_DASHBOARD_DASHBOARD_SEARCH_ENABLED=${search_enabled}" >> /etc/sysconfig/archivematica-dashboard'
sh -c 'echo "ARCHIVEMATICA_MCPSERVER_MCPSERVER_SEARCH_ENABLED=${search_enabled}" >> /etc/sysconfig/archivematica-mcp-server'

systemctl enable archivematica-mcp-server
systemctl start archivematica-mcp-server
systemctl enable archivematica-dashboard
systemctl start archivematica-dashboard
systemctl reload nginx


#
# MCPClient
#

rpm -Uvh https://forensics.cert.org/cert-forensics-tools-release-el7.rpm
rpm -Uvh https://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
yum install -y archivematica-mcp-client
ln -s /usr/bin/7za /usr/bin/7z
sed -i 's/^#TCPSocket/TCPSocket/g' /etc/clamd.d/scan.conf
sed -i 's/^Example//g' /etc/clamd.d/scan.conf
sh -c 'echo "ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_SEARCH_ENABLED=${search_enabled}" >> /etc/sysconfig/archivematica-mcp-client'

yum install -y wget
wget -nv -nc -P /var/lib/clamav \
    https://github.com/artefactual-labs/clamav-files/releases/download/20180428/main.cvd \
    https://github.com/artefactual-labs/clamav-files/releases/download/20180428/daily.cvd \
    https://github.com/artefactual-labs/clamav-files/releases/download/20180428/bytecode.cvd
chown clamupdate:clamupdate /var/lib/clamav/*cvd

systemctl enable archivematica-mcp-client
systemctl start archivematica-mcp-client
systemctl enable fits-nailgun
systemctl start fits-nailgun
systemctl enable clamd@scan
systemctl start clamd@scan
systemctl restart archivematica-dashboard
systemctl restart archivematica-mcp-server
