#!/bin/bash

# install docker
sudo curl -sSL https://get.docker.io/ | sh

# Add your user to the docker group
sudo usermod -aG docker $USER

# Login to docker
newgrp docker
