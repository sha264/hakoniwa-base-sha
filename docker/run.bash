#!/bin/bash
if [ $# -ne 1 ]
then
    echo "Usage: $0 <dev|runtime>"
    exit 1
fi
TYPE=${1}

source docker/docker_${TYPE}/env.bash

HAKONIWA_TOP_DIR=`pwd`
IMAGE_NAME=`cat docker/docker_${TYPE}/image_name.txt`
IMAGE_TAG=`cat docker/appendix/${TYPE}_latest_version.txt`
DOCKER_IMAGE=toppersjp/${IMAGE_NAME}:${IMAGE_TAG}


OS_TYPE=`bash docker/utils/detect_os_type.bash`

if [ ${OS_TYPE} != "Mac" ]
then
	docker ps > /dev/null
	if [ $? -ne 0 ]
	then
	    sudo service docker start
	    echo "waiting for docker service activation.. "
	    sleep 3
	fi
fi

if [ ${OS_TYPE} = "wsl2" ]
then
	IPADDR=`cat /etc/resolv.conf  | grep nameserver | awk '{print $NF}'`
elif [ ${OS_TYPE} = "Mac" ]
then
	if [ $# -ne 1 ]
	then
		echo "Usage: $0 <port>"
		exit 1
	fi
	IPADDR=`ifconfig | grep -A1 ${ETHER} | grep netmask | awk '{print $2}'`
else
	IPADDR="127.0.0.1"
fi

if [ $TYPE = "dev" ]
then
	docker run \
		-v ${HOST_WORKDIR}:${DOCKER_DIR} \
		-it --rm \
		--net host \
		-e OS_TYPE=${OS_TYPE} \
		--name ${IMAGE_NAME} ${DOCKER_IMAGE} 
else
	docker run \
		-v ${HOST_WORKDIR}:${DOCKER_DIR} \
		-v `pwd`/hakoniwa-core-cpp-client:${DOCKER_DIR}/hakoniwa-core-cpp-client \
		-v `pwd`/hakoniwa-master-rust:${DOCKER_DIR}/hakoniwa-master-rust \
		-it --rm \
		--net host \
		-e CORE_IPADDR=${CORE_IPADDR} \
		-e DELTA_MSEC=${DELTA_MSEC} \
		-e MAX_DELAY_MSEC=${MAX_DELAY_MSEC} \
		-e GRPC_PORT=${GRPC_PORT} \
		-e UDP_SRV_PORT=${UDP_SRV_PORT} \
		-e UDP_SND_PORT=${UDP_SND_PORT} \
		--name ${IMAGE_NAME} ${DOCKER_IMAGE} 
fi
