#!/usr/bin/env bash

# vagrant ssh -- 'bash -s' < mkTrace.sh

# Arguments:
# $1: Name of output trace file
# $2: List of output
# $3: HMac Key value for OSProfiler
TRACE_NAME=${1:-"real"}
TRACE_TYPE=${2:-"json html dot"}
TRACE_TOKEN=${3:-"SECRET_KEY"}

# Common argument for OpenStack Client
OS_ARGS=" --os-profile ${TRACE_TOKEN}"


# Utils functions

# Makes a Trace:
# Args:
# - $0 Action to perform on OpenStack client
# Returns: The Trace id
function mkTrace () {
  local OS_CMD=`openstack $1 ${OS_ARGS} 2>&1`

  echo "${OS_CMD} | fgrep 'Trace ID:' | sed 's/Trace ID: //g'"
}

# Gets a Trace:
# Args:
# - $0 Trace id
# - $1 Output file location
# Returns: The Trace id
function saveTrace () {
  set -x
  for type in ${TRACE_TYPE} ; do
    osprofiler trace show --${type} --out "$2.${type}" "$1"
  done
}


# Main

# Get all OS env variables
. /devstack/openrc admin admin


# MkTrace
# while SCN= read -r ${SCNS}; do
#   saveTrace "$(mkTrace \"${SCN}\")" "/vagrant_data/${SCN}-${TRACE_NAME}"
# done

# Scenarios
# SCNS="hypervisor list
# image list
# flavor list
# server create --flavor=m1.tiny --image=cirros-0.3.4-x86_64-uec test
# "

saveTrace "$(mkTrace 'hypervisor list')" "/vagrant_data/hypervisor-list-${TRACE_NAME}"
# saveTrace "$(mkTrace 'image list')" "/vagrant_data/image-list-${TRACE_NAME}"
# saveTrace "$(mkTrace 'flavor list')" "/vagrant_data/flavor-list-${TRACE_NAME}"
# saveTrace "$(mkTrace 'server create --flavor=m1.tiny --image=cirros-0.3.4-x86_64-uec test')"\
#           "/vagrant_data/server-create-${TRACE_NAME}"
# sleep 100
# saveTrace "$(mkTrace 'server show test')" "/vagrant_data/server-show-${TRACE_NAME}"
