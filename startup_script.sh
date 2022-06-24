#!/bin/sh

apt update
apt install -y ruby-full ruby-bundler build-essential mongodb git
systemctl start mongodb
systemctl enable mongodb
cd /home/yc-user
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
