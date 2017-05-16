#!/bin/bash
set -e

# Convert COMMAND variable into an array
# Simulating positional parameter behaviour
IFS=' ' read -r -a CMD_ARRAY <<< "$COMMAND"

# explicitly setting positional parameters ($@) to CMD_ARRAY
set -- "${CMD_ARRAY[@]}"
# From this point, positional parameters ($@)will be set to the parameters in the COMMAND variable.

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { echo "$ $@" 1>&2; "$@" || die "cannot $*"; }

setup_autoregister_properties_file_for_elastic_agent() {
  echo "agent.auto.register.key=${GO_EA_AUTO_REGISTER_KEY}" >> $1
  echo "agent.auto.register.environments=${GO_EA_AUTO_REGISTER_ENVIRONMENT}" >> $1
  echo "agent.auto.register.elasticAgent.agentId=${GO_EA_AUTO_REGISTER_ELASTIC_AGENT_ID}" >> $1
  echo "agent.auto.register.elasticAgent.pluginId=${GO_EA_AUTO_REGISTER_ELASTIC_PLUGIN_ID}" >> $1
  echo "agent.auto.register.hostname=${AGENT_AUTO_REGISTER_HOSTNAME}" >> $1

  export GO_SERVER_URL="${GO_EA_SERVER_URL}"
  # unset variables, so we don't pollute and leak sensitive stuff to the agent process...
  unset GO_EA_AUTO_REGISTER_KEY GO_EA_AUTO_REGISTER_ENVIRONMENT GO_EA_AUTO_REGISTER_ELASTIC_AGENT_ID GO_EA_AUTO_REGISTER_ELASTIC_PLUGIN_ID GO_EA_SERVER_URL AGENT_AUTO_REGISTER_HOSTNAME
}

setup_autoregister_properties_file_for_normal_agent() {
  echo "agent.auto.register.key=${AGENT_AUTO_REGISTER_KEY}" >> $1
  echo "agent.auto.register.resources=${AGENT_AUTO_REGISTER_RESOURCES}" >> $1
  echo "agent.auto.register.environments=${AGENT_AUTO_REGISTER_ENVIRONMENTS}" >> $1
  echo "agent.auto.register.hostname=${AGENT_AUTO_REGISTER_HOSTNAME}" >> $1

  # unset variables, so we don't pollute and leak sensitive stuff to the agent process...
  unset AGENT_AUTO_REGISTER_KEY AGENT_AUTO_REGISTER_RESOURCES AGENT_AUTO_REGISTER_ENVIRONMENTS AGENT_AUTO_REGISTER_HOSTNAME
}

setup_autoregister_properties_file() {
  if [ -n "$GO_EA_SERVER_URL" ]; then
    setup_autoregister_properties_file_for_elastic_agent "$1"
    try chown go:go $1
  else
    setup_autoregister_properties_file_for_normal_agent "$1"
    try chown go:go $1
  fi
}

VOLUME_DIR="/godata"

# these 3 vars are used by `/go-agent/agent.sh`, so we export
export AGENT_WORK_DIR="/go"
export STDOUT_LOG_FILE="/go/go-agent-bootstrapper.out.log"

# no arguments are passed so assume user wants to run the gocd server
# we prepend "/go-agent/agent.sh" to the argument list
if [[ $# -eq 0 ]] ; then
	set -- /go-agent/agent.sh "$@"
fi

# if running go server as root, then initialize directory structure and call ourselves as `go` user
if [ "$1" = '/go-agent/agent.sh' ]; then

  if [ "$(id -u)" = '0' ]; then
    server_dirs=(config logs pipelines)

    yell "Creating directories and symlinks to hold GoCD configuration, data, and logs"

    # ensure working dir exist
    if [ ! -e "${AGENT_WORK_DIR}" ]; then
      try mkdir "${AGENT_WORK_DIR}"
      try chown go:go "${AGENT_WORK_DIR}"
    fi

    # ensure proper directory structure in the volume directory
    if [ ! -e "${VOLUME_DIR}" ]; then
      try mkdir "${VOLUME_DIR}"
      try chown go:go "${AGENT_WORK_DIR}"
    fi

    for each_dir in "${server_dirs[@]}"; do
      if [ ! -e "${VOLUME_DIR}/${each_dir}" ]; then
        try mkdir -v "${VOLUME_DIR}/${each_dir}"
        try chown go:go "${VOLUME_DIR}/${each_dir}"
      fi

      if [ ! -e "${AGENT_WORK_DIR}/${each_dir}" ]; then
        try ln -sv "${VOLUME_DIR}/${each_dir}" "${AGENT_WORK_DIR}/${each_dir}"
        try chown go:go "${AGENT_WORK_DIR}/${each_dir}"
      fi
    done

    setup_autoregister_properties_file "${AGENT_WORK_DIR}/config/autoregister.properties"
    touch "${STDOUT_LOG_FILE}"
    chown go:go "${STDOUT_LOG_FILE}"
    try exec /usr/local/sbin/tini -- /usr/local/sbin/gosu go "$0" "$@" >> ${STDOUT_LOG_FILE} 2>&1
  fi
fi

try exec "$@"
