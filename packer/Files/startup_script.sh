#!/bin/sh

sleep 120
sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential mongodb git
sudo systemctl start mongodb
sudo systemctl enable mongodb
mkdir /app
cd /app
sudo git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
cp -f /tmp/reddit.service /etc/systemd/system/reddit.service
sudo systemctl daemon-reload
sudo systemctl enable reddit.service
sudo systemctl start reddit.service
