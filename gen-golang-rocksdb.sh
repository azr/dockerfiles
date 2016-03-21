#!/bin/bash

set -e # leave at first error

function usage {
    echo "Usage: GO_VERSION=1.6 ROCKSDB_TAG=v4.4 ./gen-golang-rocksdb.sh"
}

if [ -z $GO_VERSION ] || [ -z $ROCKSDB_TAG ]; then
    echo "Please specify GO_VERSION and ROCKSDB_TAG."
    usage
    exit 1
fi

DFDIR="golang:${GO_VERSION}-rocksdb:${ROCKSDB_TAG}"

function echo_Dockerfile {
cat <<EOF
FROM golang:${GO_VERSION}

# update
RUN apt-get update -y

#
# based on Rocksdb install.md:
#

# Upgrade your gcc to version at least 4.7 to get C++11 support.
RUN apt-get install -y build-essential checkinstall


RUN apt-get install -y build-essential checkinstall

# Install gflags
RUN apt-get install -y libgflags-dev

# Install snappy
RUN apt-get install -y libsnappy-dev

# Install zlib
RUN apt-get install -y zlib1g-dev

# Install bzip2
RUN apt-get install -y libbz2-dev

# Clone rocksdb
RUN cd /tmp && git clone https://github.com/facebook/rocksdb.git && cd rocksdb && git checkout ${ROCKSDB_TAG} && make clean && make
EOF
}

mkdir -p ${DFDIR}
DockerfilePath=${DFDIR}/Dockerfile
echo_Dockerfile > ${DockerfilePath}

cat ${DockerfilePath}