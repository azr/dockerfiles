#!/bin/bash

set -e # leave at first error

function usage {
    echo "Usage: GO_VERSION=1.6 GC_SDK_VERSION=0.9.65 APPENGINE_VERSION=1.9.35 ./gen-golang+google-cloud-sdk+google-cloud-appengine.sh"
}

if [ -z $GO_VERSION ] || [ -z $GC_SDK_VERSION ] || [ -z $APPENGINE_VERSION ]; then
    echo "Please specify GO_VERSION, GC_SDK_VERSION and APPENGINE_VERSION."
    usage
    exit 1
fi

DFDIR="golang:${GO_VERSION}-gcloud:${GC_SDK_VERSION}-appengine:${APPENGINE_VERSION}"

function echo_Dockerfile {
cat <<EOF
FROM golang:${GO_VERSION}

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i '1i deb     http://gce_debian_mirror.storage.googleapis.com/ wheezy         main' /etc/apt/sources.list
RUN apt-get update -y && apt-get install -y -qq --no-install-recommends wget unzip openssh-client curl build-essential ca-certificates git mercurial bzr python-openssl && apt-get clean

WORKDIR /

# Install the Google Cloud SDK.
ENV HOME /
ENV CLOUDSDK_PYTHON_SITEPACKAGES 1
RUN wget https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.zip && unzip google-cloud-sdk.zip && rm google-cloud-sdk.zip

# Lock the Google Cloud SDK version.
ENV CLOUDSDK_COMPONENT_MANAGER_FIXED_SDK_VERSION ${GC_SDK_VERSION}
RUN google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/.bashrc --additional-components app-engine-java app-engine-python app kubectl alpha beta pkg-go pkg-python pkg-java preview

# Disable updater check for the whole installation.
# Users won't be bugged with notifications to update to the latest version of gcloud.
RUN google-cloud-sdk/bin/gcloud config set --installation component_manager/disable_update_check true || google-cloud-sdk/bin/gcloud config set component_manager/disable_update_check true

# Disable updater completely.
# Running `gcloud components update` doesn't really do anything in a union FS.
# Changes are lost on a subsequent run.
RUN sed -i -- 's/\"disable_updater\": false/\"disable_updater\": true/g' /google-cloud-sdk/lib/googlecloudsdk/core/config.json || echo nope, too soon for this

RUN mkdir /.ssh
ENV PATH /google-cloud-sdk/bin:\$PATH
VOLUME ["/.config"]
CMD bash

# install go appengine sdk
RUN wget https://storage.googleapis.com/appengine-sdks/featured/go_appengine_sdk_linux_amd64-${APPENGINE_VERSION}.zip && \
    unzip go_appengine_sdk_linux_amd64-${APPENGINE_VERSION}.zip
ENV PATH \$PATH:/go_appengine

EOF
}

mkdir -p ${DFDIR}
DockerfilePath=${DFDIR}/Dockerfile
echo_Dockerfile > ${DockerfilePath}

cat ${DockerfilePath}