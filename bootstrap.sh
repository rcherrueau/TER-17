#!/usr/bin/env bash
set -x

# # Install MongoDB/git
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
sudo apt-get update
sudo apt-get install -y git

# Download DevStack
git clone https://git.openstack.org/openstack-dev/devstack /devstack --single-branch

# Clone only the required branch to save time
# see https://bugs.launchpad.net/devstack/+bug/1412244
sed -i 's/git_timed clone $git_clone_flags $git_remote $git_dest$/& -b $git_ref/' /devstack/functions-common

# Create stack user and group and give her access to 'devstack
sed -i 's/HOST_IP=${HOST_IP:-}/ HOST_IP=10.0.2.15/' /devstack/stackrc
/devstack/tools/create-stack-user.sh
chown -R stack:stack /devstack
echo "vagrant ALL=(stack) NOPASSWD:ALL" >> /etc/sudoers

# # get the requested files in the proper place ( from http://docs.openstack.org/releasenotes/horizon/unreleased.html#id2 )
# sudo wget https://raw.githubusercontent.com/openstack/horizon/master/openstack_dashboard/local/local_settings.d/_9030_profiler_settings.py.example -O /opt/stack/horizon/openstack_dashboard/local/local_settings.d/_9030_profiler_settings.py
# sudo wget https://raw.githubusercontent.com/openstack/horizon/master/openstack_dashboard/contrib/developer/enabled/_9030_profiler.py -O /opt/stack/horizon/openstack_dashboard/local/enabled/_9030_profiler.py

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
disable_service tempest swift

# Set ceilometer with gnocchi
# enable_plugin gnocchi https://github.com/openstack/gnocchi master
enable_plugin ceilometer https://git.openstack.org/openstack/ceilometer.git
CEILOMETER_BACKEND=mongodb
# CEILOMETER_BACKEND=gnocchi

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

[[post-config|\$CEILOMETER_CONF]]
[DEFAULT]
event_dispatchers = database
# meter_dispatchers = database
# meter_dispatchers = gnocchi

[oslo_messaging_notifications]
topics = notification, profiler

# Run DevStack
sudo -H -u stack ./unstack.sh
sudo -H -u stack ./stack.sh
