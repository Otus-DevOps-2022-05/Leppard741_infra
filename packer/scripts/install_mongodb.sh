#!/bin/sh

sudo sleep 120
sudo apt update
sudo apt install -y python3
sudo apt install -y mongodb
sudo systemctl start mongodb
sudo systemctl enable mongodb
