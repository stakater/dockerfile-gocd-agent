#!/bin/bash
_gocd_version=$1
_gocd_tag=$2
_release_build=false

if [ -z "${_gocd_version}" ]; then
	source GOCD_VERSION
	_gocd_version=$GOCD_VERSION
	_gocd_tag=v${GOCD_VERSION}
	_release_build=true
fi

echo "GOCD_VERSION: ${_gocd_version}"
echo "DOCKER TAG: ${_gocd_tag}"
echo "RELEASE BUILD: ${_release_build}"

docker build --build-arg GOCD_VERSION=${_gocd_version} --tag "stakater/gocd-agent:${_gocd_tag}"  --no-cache=true .

if [ $_release_build == true ]; then
	docker tag "stakater/gocd-agent:${_gocd_tag}" "stakater/gocd-agent:latest"
fi