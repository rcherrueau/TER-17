#!/usr/bin/env bash

# Best to trace is start from a fresh installation. Remember the use
# of `vagrant snapshot`!
# $ vagrant snapshot save time0
# ...
# $ vagrant suspend
# $ vagrant snapshot restore --no-provison time0

# Call:
#   vagrant ssh -- 'bash -s' < mkTrace.sh trace_name trace_types trace_token
# With:
# $1: trace_name  Name of output trace file
# $2: trace_types List of output trace type
# $3: trace_token HMac Key value for OSProfiler
TRACE_NAME=${1:-"real"}
TRACE_TYPES=${2:-"json html"}
TRACE_TOKEN=${3:-"SECRET_KEY"}


# Utils functions

# mkTrace: os_action → trace_id
# Makes a Trace.
#
# With:
# - $1: os_action Action to perform on OpenStack client, e.g.,
#                 'hypervisor list', 'server create ...'
# - $2: trace_id  Trace id
function mkTrace () {
  local TRACE_ID=$(openstack $1 --os-profile ${TRACE_TOKEN} 2>&1\
                       | fgrep 'Trace ID:'\
                       | sed 's/Trace ID: //g')

  echo "${TRACE_ID}"
}

# saveTrace: trace_id → [trace_type] → output_file → ( )
# Gets a Trace and saves it.
#
# with:
# - $1: trace_id     Trace id to save
# - $2: [trace_type] A list of trace type (eg, "json html")
# - $3: output_file  Output file location without extension
function saveTrace () {
  for type in $2 ; do
    osprofiler trace show --${type} --out "$3.${type}" "$1"
  done
}


# Main

# Get all OS env variables
. /devstack/openrc admin admin

set -x

# Scenarios
saveTrace $(mkTrace 'hypervisor list') ${TRACE_TYPES} "/vagrant_data/hypervisor-list-${TRACE_NAME}"
saveTrace $(mkTrace 'image list') ${TRACE_TYPES} "/vagrant_data/image-list-${TRACE_NAME}"
saveTrace $(mkTrace 'flavor list') ${TRACE_TYPES} "/vagrant_data/flavor-list-${TRACE_NAME}"
saveTrace $(mkTrace 'server create --flavor=m1.tiny --image=cirros-0.3.4-x86_64-uec test')\
          ${TRACE_TYPES} "/vagrant_data/server-create-${TRACE_NAME}"
