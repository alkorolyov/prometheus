#!/bin/bash
############## PROMETHEUS_INSTALL.sh #######################

# Define ANSI escape codes for colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

BIN_DIR='/usr/local/bin'
CONFIG_DIR='/etc/prometheus'
DATA_DIR='/var/lib/prometheus'
USER='prometheus'
GROUP=$USER

echo -e "=> ${GREEN}Start installation of PROMETHEUS service${NC}"

if [[ $UID -ne 0 ]]; then
    echo "Installation should be run as root"
    exit
fi

# echo "=> Apt update"
# apt-get -qq update

echo "=> Download and unpack latest prometheus to /tmp"
cd /tmp
latest_prometheus=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "browser_download_url.*linux-amd64" | cut -d '"' -f 4)
echo $latest_prometheus
wget -q --show-progress $latest_prometheus
tar vxf prometheus*.tar.gz
cd prometheus*/

echo "=> Create config and data dirs: $CONFIG_DIR $DATA_DIR"
mkdir $CONFIG_DIR
mkdir $DATA_DIR

echo "=> Create $USER user/group"

useradd -rs /bin/false $USER

echo "=> Install binaries to $BIN_DIR"
cp -f prometheus $BIN_DIR
cp -f promtool $BIN_DIR
chown $USER:$GROUP $BIN_DIR/prometheus
chown $USER:$GROUP $BIN_DIR/promtool

echo "=> Create config prometheus.yml"
CONFIG_CONTENT="
############### Prometheus CONFIG #################
global:
  scrape_interval: 5s

# change default name
scrape_configs:
- job_name: node_name # default name
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

echo "=> Install web and config files to $CONFIG_DIR"
cp -rf consoles $CONFIG_DIR
cp -rf console_libraries $CONFIG_DIR
cp -r prometheus.yml $CONFIG_DIR
chown $USER:$GROUP $CONFIG_DIR
chown -R $USER:$GROUP $CONFIG_DIR/consoles
chown -R $USER:$GROUP $CONFIG_DIR/console_libraries
chown -R $USER:$GROUP $DATA_DIR

echo "=> Create service file"
SERVICE_CONTENT="
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$GROUP
Type=simple
ExecStart=$BIN_DIR/prometheus --config.file $CONFIG_DIR/prometheus.yml --storage.tsdb.path $DATA_DIR/  --web.console.templates=$CONFIG_DIR/consoles --web.console.libraries=$CONFIG_DIR/console_libraries

[Install]
WantedBy=multi-user.target
"
echo -e "$SERVICE_CONTENT" > /etc/systemd/system/prometheus.service

echo "=> Start service"
systemctl daemon-reload
systemctl start prometheus

# check service status
status=$(systemctl is-active prometheus)
if [[ "$status" == "active" ]]; then
    status="${GREEN}$status${NC}"
else
    status="${RED}$status${NC}"
fi
echo -e "=> Service status: $status"

systemctl enable prometheus

echo "=> Allow ports for local firewall"
sudo ufw allow 9090/tcp
sudo ufw allow 9100/tcp

echo "=> Delete tmp files"
cd /tmp
rm -rf /tmp/prometheus*/
rm -rf /tmp/prometheus*

echo "=> Installation complete!"