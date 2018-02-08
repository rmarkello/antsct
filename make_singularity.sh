#!/usr/bin/env bash

# create the Dockerfile and build the container
python code/make_docker.py
docker build -t antsct .
rm Dockerfile

# push the container to DockerHub
docker login
dockerhubuser=$( docker info | grep Username | cut -d ' ' -f2 )
docker tag $( docker images antsct:latest -q ) ${dockerhubuser}/antsct:v1
docker push ${dockerhubuser}/antsct:v1

# make the Singularity recipe file (so that it can be run and accept commands)
cp Singularity Singularity.bak
sed -i "s/##username##/${dockerhubuser}/g" Singularity

# build the Singularity container
sudo singularity build antsct.simg Singularity
rm Singularity; mv Singularity.bak Singularity
