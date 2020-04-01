#!/bin/bash

# Check if Docker is running
docker info >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	echo "Docker NOT running!"
	exit 1
fi

# Set default rate value in case is not provided as an input
_RATE=${1:-10kpps}

# Check if NFVBench image has been defined
docker image ls | grep -q nfvbench >/dev/null 2>&1 || docker pull opnfv/nfvbench:4.2.2

# Check if NFVBench container has been defined
_PID=$(docker ps --filter "name=nfvbench" --quiet --all)
if [[ "${_PID}" == "" ]]; then
	docker run --name nfvbench --detach \
		--privileged \
		--net=host \
		-v /lib/modules/$(uname -r):/lib/modules/$(uname -r) \
		-v /usr/src/kernels:/usr/src/kernels \
		-v /dev:/dev \
		-v $HOME:/tmp/nfvbench \
		opnfv/nfvbench:4.2.2
fi

# Check if NFVBench container is running
_STATUS=$(docker ps --filter "name=nfvbench" --filter "status=running" --quiet)
if [[ "${_STATUS}" == "" ]]; then
	docker start nfvbench
fi

# Define NFVBench CLI alias
nfvbench='docker exec -it nfvbench nfvbench'

# Check if NFVBench is an healty state (simple function test)
sleep 2s && ${nfvbench} --version >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	echo "NFVBench not in a good state"
	exit 1
fi

# Check if results directory exist and eventually create it
[[ -d ./results ]] || mkdir results

# Save test time and date
_DATE="$(date +%m_%d_%y-%H_%M_%S)"

# Run traffic
${nfvbench} -c /tmp/nfvbench/nfvbench.cfg --rate ${_RATE} --json /tmp/nfvbench/results/result_${_DATE}.json |& tee -a ./results/stdout_${_DATE}.log
