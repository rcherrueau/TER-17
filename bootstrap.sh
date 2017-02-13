#!/usr/bin/env bash
set -x

# Download DevStack
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
sudo apt-get update
sudo apt-get install -y git mongodb-org

git clone https://git.openstack.org/openstack-dev/devstack /devstack --single-branch

# clone only the required branch to save time
# see https://bugs.launchpad.net/devstack/+bug/1412244
sed -i 's/git_timed clone $git_clone_flags $git_remote $git_dest$/& -b $git_ref/' /devstack/functions-common
#sed -i 's/KEYSTONE_TOKEN_FORMAT=${KEYSTONE_TOKEN_FORMAT:-}/KEYSTONE_TOKEN_FORMAT=${KEYSTONE_TOKEN_FORMAT:-fernet}/' /devstack/lib/keystone

#Create stack user and group and give her access to 'devstack

sed -i 's/HOST_IP=${HOST_IP:-}/ HOST_IP=10.0.2.15/' /devstack/stackrc
/devstack/tools/create-stack-user.sh
chown -R stack:stack /devstack 
echo "vagrant ALL=(stack) NOPASSWD:ALL" >> /etc/sudoers

# get the requested files in the proper place ( from http://docs.openstack.org/releasenotes/horizon/unreleased.html#id2 )
sudo wget https://raw.githubusercontent.com/openstack/horizon/master/openstack_dashboard/local/local_settings.d/_9030_profiler_settings.py.example -O /opt/stack/horizon/openstack_dashboard/local/local_settings.d/_9030_profiler_settings.py
sudo wget https://raw.githubusercontent.com/openstack/horizon/master/openstack_dashboard/contrib/developer/enabled/_9030_profiler.py -O /opt/stack/horizon/openstack_dashboard/local/enabled/_9030_profiler.py

cd /devstack

# Make local configuration file required by DevStack
cat > local.conf <<- EOF
[[local|localrc]]
HOST_IP=10.0.2.15
ADMIN_PASSWORD=admin
DATABASE_PASSWORD=admin
RABBIT_PASSWORD=admin
SERVICE_PASSWORD=admin
GIT_DEPTH=1
enable_plugin ceilometer https://git.openstack.org/openstack/ceilometer.git
disable_service tempest swift

[[post-config|\$KEYSTONE_CONF]]
[profiler]
enabled = True
trace_sqlalchemy = True
hmac_keys = SECRET_KEY
connection_string = messaging://

[[post-config|\$GLANCE_API_CONF]]
[profiler]
enabled = True
trace_sqlalchemy = True
hmac_keys = SECRET_KEY
connection_string = messaging://

[[post-config|\$NEUTRON_CONF]]
[profiler]
enabled = True
trace_sqlalchemy = True
hmac_keys = SECRET_KEY
connection_string = messaging://

[[post-config|\$CINDER_CONF]]
[profiler]
enabled = True
trace_sqlalchemy = True
hmac_keys = SECRET_KEY
connection_string = messaging://
EOF

# Run DevStack
sudo -H -u stack ./unstack.sh 
sudo -H -u stack ./stack.sh

