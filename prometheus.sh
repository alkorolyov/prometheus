#!/bin/bash

############## PROMETHEUS_INSTALL.sh #######################

echo "apt update"
apt-get -qq update

echo "create prometheus user/group"
useradd -rs /bin/false prometheus

echo "Download and unpack latest prometheus to /tmp"
cd /tmp
wget -q $(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "browser_download_url.*linux-amd64" | cut -d '"' -f 4)
tar vxf prometheus*.tar.gz
cd prometheus*/

echo 'create install dir'
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

echo "create config"
CONFIG_CONTENT="
global:
  scrape_interval: 5s

scrape_configs:
- job_name: node_name
  static_configs:
  - targets: ['localhost:9100', 'localhost:9090']

remote_write:
- url: https://prometheus-prod-22-prod-eu-west-3.grafana.net/api/prom/push
  basic_auth:
    username: 1120366
    password: eyJrIjoiMDRhNGYwMDU1ODljMGU2M2I1MWM5YTgyMDg1MGRiZWM5MjY3M2ExYiIsIm4iOiJtaWNyby1nY3AiLCJpZCI6OTEyNzQ2fQ==
"

echo -e "$CONFIG_CONTENT" > /etc/prometheus/prometheus.yml

echo "move files and change ownerships"
cp -f prometheus /usr/local/bin
cp -f promtool /usr/local/bin
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

cp -rf consoles /etc/prometheus
cp -rf console_libraries /etc/prometheus
chown prometheus:prometheus /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
chown -R prometheus:prometheus /var/lib/prometheus

echo "create service file"
SERVICE_CONTENT="
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/  --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
"
echo -e "$SERVICE_CONTENT" > /etc/systemd/system/prometheus.service

echo "start service"
sudo systemctl daemon-reload
sudo systemctl start prometheus
# sudo systemctl status prometheus
sudo systemctl enable prometheus

echo "allow ports"
sudo ufw allow 9090/tcp
sudo ufw allow 9100/tcp

echo "delete tmp files"
cd /tmp
rm -rf /tmp/prometheus*/
rm -rf /tmp/prometheus*

echo "finished!"
