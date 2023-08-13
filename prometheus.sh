#!/bin/bash

############## PROMETHEUS_INSTALL.sh #######################

echo "=> Start installation of prometheus service"

if [[ $UID -ne 0 ]]; then
    echo "Installation should be run as root. Use 'sudo bash ./prometheus.sh'"
    exit
fi

echo "=> Apt update"
apt-get -qq update

echo "=> Download and unpack latest prometheus to /tmp"
cd /tmp
LATEST_PROMETHEUS=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "browser_download_url.*linux-amd64" | cut -d '"' -f 4)
echo "Latest prometheus version: '$LATEST_PROMETHEUS'"
wget -q LATEST_PROMETHEUS
tar vxf prometheus*.tar.gz
cd prometheus*/

echo '=> Create installation dirs: /etc/prometheus /var/lib/prometheus'
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

echo "=> Create prometheus user/group"
useradd -rs /bin/false prometheus

echo "=> Install executables to /usr/local/bin"
cp -f prometheus /usr/local/bin
cp -f promtool /usr/local/bin
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

echo "=> Create config prometheus.yml"
CONFIG_CONTENT="
############### Prometheus CONFIG #################
global:
  scrape_interval: 5s

scrape_configs:
- job_name: node_name # change this
  static_configs:
  - targets: ['localhost:9100', 'localhost:9090']

# graphana cloud remote write
remote_write:
- url: https://prometheus-prod-22-prod-eu-west-3.grafana.net/api/prom/push
  basic_auth:
    username: 1120366
    password: eyJrIjoiMDRhNGYwMDU1ODljMGU2M2I1MWM5YTgyMDg1MGRiZWM5MjY3M2ExYiIsIm4iOiJtaWNyby1nY3AiLCJpZCI6OTEyNzQ2fQ==
"

echo -e "$CONFIG_CONTENT" > prometheus.yml

# edit config if needed
nano prometheus.yml

echo "=> Install web and config files to /etc/prometheus"
cp -rf consoles /etc/prometheus
cp -rf console_libraries /etc/prometheus
cp -r prometheus.yml /etc/prometheus
chown prometheus:prometheus /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
chown -R prometheus:prometheus /var/lib/prometheus

echo "=> Create service file"
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

echo "=> Start service"
sudo systemctl daemon-reload
sudo systemctl start prometheus
# sudo systemctl status prometheus
sudo systemctl enable prometheus

echo "=> Allow ports for local firewall"
sudo ufw allow 9090/tcp
sudo ufw allow 9100/tcp

echo "=> Delete tmp files"
cd /tmp
rm -rf /tmp/prometheus*/
rm -rf /tmp/prometheus*

echo "=> Installation complete!"
