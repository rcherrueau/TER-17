#!/usr/bin/env bash
set -x


# 1. Download Devstack
apt update -y; apt install -y git sudo
git clone --depth=1 --branch=stable/ocata\
    https://git.openstack.org/openstack-dev/devstack\
    /devstack


# 2. Patch Devstack
# Clone only the required branch to save time
# see https://bugs.launchpad.net/devstack/+bug/1412244
sed -i 's/git_timed clone $git_clone_flags $git_remote $git_dest$/& -b $git_ref/' /devstack/functions-common
sed -i 's/HOST_IP=${HOST_IP:-}/ HOST_IP=10.0.2.15/' /devstack/stackrc


# 3. Create `stack` user & group
/devstack/tools/create-stack-user.sh
# Give her access to `/devstack` directory and add it to sudoers
chown -R stack:stack /devstack
echo "vagrant ALL=(stack) NOPASSWD:ALL" >> /etc/sudoers


# 4. Make the configuration file required by DevStack
cat > /devstack/local.conf <<- EOF
[[local|localrc]]
ADMIN_PASSWORD=admin
DATABASE_PASSWORD=admin
RABBIT_PASSWORD=admin
SERVICE_PASSWORD=admin
GIT_DEPTH=1

# http://docs.openstack.org/developer/ceilometer/install/development.html#configuring-devstack
# Enable the Ceilometer devstack plugin
enable_plugin panko https://git.openstack.org/openstack/panko stable/ocata
enable_plugin ceilometer https://git.openstack.org/openstack/ceilometer stable/ocata
enable_plugin osprofiler https://git.openstack.org/openstack/osprofiler stable/ocata

OSPROFILER_HMAC_KEYS=SECRET_KEY

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


# 5. Run Devstack as stack user
# Run DevStack
sudo -H -u stack /devstack/unstack.sh
sudo -H -u stack /devstack/stack.sh
