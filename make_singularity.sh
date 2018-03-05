#!/usr/bin/env bash

# create the Dockerfile and build the container
python make_docker.py

# spin up local registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# tag and push image to local registry
docker tag antsct localhost:5000/antsct
docker push localhost:5000/antsct
wait ${!}

# create singularity image from local registry; require singularity >=2.4.2
SINGULARITY_NOHTTPS=true singularity pull docker://localhost:5000/antsct

# remove registry and docker image
REG=$( docker ps -alq ); docker stop ${REG}; docker rm ${REG}
docker rmi -f localhost:5000/antsct
