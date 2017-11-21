#!/usr/bin/env bash

set -e
git submodule update --init --recursive
make create-volumes
docker-compose up -d --build
make bootstrap
make restart-am-services
docker-compose stop elasticsearch
