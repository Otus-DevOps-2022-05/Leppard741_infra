#!/bin/sh
apt-get update
apt-get install -y mongodb
systemctl start mongodb
systemctl enable mongodb
