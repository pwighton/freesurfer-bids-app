#!/bin/bash

###############################################################################
# Generate a Dockerfile and Singularity recipe for building the BIDS-Apps Freesurfer container.
#
# Steps to build, upload, and deploy the BIDS-Apps Freesurfer docker and/or singularity image:
#
# 1. Create or update the Dockerfile and Singuarity recipe:
# bash generate_freesurfer_images.sh
#
# 2. Build the docker image:
# docker build -t freesurfer -f Dockerfile .
#
#    and/or singularity image:
# singularity build freesurfer.simg Singularity
#
# 3. Push to Docker hub:
# (https://docs.docker.com/docker-cloud/builds/push-images/)
# export DOCKER_ID_USER="bids"
# docker login
# docker tag mindboggle bids/mindboggle  # See: https://docs.docker.com/engine/reference/commandline/tag/
# docker push nipy/mindboggle
#
# 4. Pull from Docker hub (or use the original):
# docker pull bids/freesurfer
#
# In the following, the Docker container can be the original (bids)
# or the pulled version (bids/freesurfer), and is given access to /Users/filo
# on the host machine.
#
# 5. Enter the bash shell of the Docker container, and add port mappings:
# docker run -ti --rm \
#                -v /Users/filo/data/ds005:/bids_dataset:ro \
#                -v /Users/filo/outputs:/outputs \
#                -v /Users/filo/freesurfer_license.txt:/license.txt \
#                bids/freesurfer \
#                /bids_dataset /outputs participant --participant_label 01 \
#                --license_file "/license.txt"
#
###############################################################################

# This is using a fork of neurodocker, until changes get merged upstream
# See: 
#  - github.com/pwighton/neurodocker
#  - github.com/pwighton/fs-docker
#image="repronim/neurodocker"
#image="pwighton/neurodocker:master@sha256:14f185abe87108e505b41b9170d887e998e580b74fe744b4e3893c8ae0d66c06"
image="pwighton/neurodocker:latest"
fs_license_file=~/lcn/license.txt
fs_license_base64=`cat ${fs_license_file} | base64 -w 999`

# Generate a dockerfile for building BIDS-Apps Freesurfer container
docker run --rm ${image} generate docker \
  --base-image ubuntu:xenial \
  --pkg-manager apt \
  --yes \
  --freesurfer \
    license_base64=${fs_license_base64} \
	  method=source \
	  repo=https://github.com/pwighton/freesurfer.git \
	  version=20210513-fs-infant-dev-merge \
  --run 'apt-get update -qq && apt-get install -y -q curl' \
  --run 'curl -sL https://deb.nodesource.com/setup_14.x | bash -' \
  --run 'apt-get install -y -q nodejs' \
  --run 'npm install -g bids-validator@0.19.8' \
  --run 'mkdir root/matlab && touch root/matlab/startup.m' \
  --run 'mkdir /scratch' \
  --run 'mkdir /local-scratch' \
  --copy ./run.py /run.py \
  --run  'chmod +x /run.py' \
  --copy ./version /version \
  --entrypoint '/neurodocker/startup.sh /run.py' \
> Dockerfile

# Generate a singularity recipe for building BIDS-Apps Freesurfer container
#docker run --rm ${image} generate docker \
#  --base-image ubuntu:xenial \
#  --pkg-manager apt \
#  --yes \
#  --freesurfer \
#    license_base64=${fs_license_base64} \
#	  method=source \
#	  repo=https://github.com/pwighton/freesurfer.git \
#	  version=20210513-fs-infant-dev-merge \
#	--run-bash 'curl -sL https://deb.nodesource.com/setup_6.x | bash -' \
#  --install nodejs \
#  --run-bash 'npm install -g bids-validator@0.19.8' \
#  --run 'mkdir root/matlab && touch root/matlab/startup.m' \
#  --run 'mkdir /scratch' \
#  --run 'mkdir /local-scratch' \
#  --copy run.py '/run.py' \
#  --run  'chmod +x /run.py' \
#  --copy version '/version' \
#  --entrypoint '/neurodocker/startup.sh /run.py' \
#> Singularity
