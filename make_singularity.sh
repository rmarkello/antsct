#!/usr/bin/env bash

TAG=antsct
VERSION=v1

# create the Dockerfile and build the container
python code/make_docker.py
docker build -t ${TAG} .
rm Dockerfile

# push the container to DockerHub
docker login
dockerhubuser=$( docker info | grep Username | cut -d ' ' -f2 )
docker tag $( docker images ${TAG}:latest -q ) ${dockerhubuser}/${TAG}:${VERISON}
docker push ${dockerhubuser}/${TAG}:${VERISON}

# make the Singularity recipe file (so that it can be run and accept commands)
cp Singularity Singularity.bak
sed -i "s/##username##/${dockerhubuser}/g" Singularity
sed -i "/##tag##/${TAG}/g" Singularity
sed -i "/##version##/${VERSION}" Singularity

# build the Singularity container
sudo singularity build antsct.simg Singularity
rm Singularity; mv Singularity.bak Singularity
