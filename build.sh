#!/bin/bash
_gocdagent_version="17.1.0"
_gocdagent_tag="${_gocdagent_version}"
_release_build=$1

echo "GOCD-AGENT_VERSION: ${_gocdagent_version}"
echo "DOCKER TAG: ${_gocdagent_tag}"
echo "RELEASE BUILD: ${_release_build}"

docker build --tag "stakater/gocd-agent:${_gocdagent_tag}"  --no-cache=true .

if [ $_release_build == true ]; then
	docker build --tag "stakater/gocd-agent:latest"  --no-cache=true .
        docker push "stakater/gocd-agent:${_gocdagent_tag}"
        docker push "stakater/gocd-agent:latest"
fi
