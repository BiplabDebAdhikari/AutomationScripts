#!/bin/bash

# add Jenkins key to the server and repository
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > \
    /etc/apt/sources.list.d/jenkins.list'

sudo apt-get update

echo "Installing Java..."
sudo apt install default-jdk -y

echo "Installing Maven..."
sudo apt-get -y install maven

echo "Installing Jenkins..."
sudo apt-get install jenkins -y

echo "Altering firewall rules..."
sudo ufw allow 8080/tcp

echo "Process complete"