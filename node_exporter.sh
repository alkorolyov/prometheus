#!/bin/bash
###### node_exporter service ########

BIN_DIR='/usr/local/bin'

# Define ANSI escape codes for colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "=> Start installation of NODE_EXPORTER service"

if [[ $UID -ne 0 ]]; then
    echo "Installation should be run as root. Use 'sudo bash ./node_exporter.sh'"
    exit
fi

echo "=> Download and extract latest node_exporter"
cd /tmp
latest_node_extractor=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "browser_download_url.*linux-amd64" | cut -d '"' -f 4)
wget -q --show-progress $latest_node_extractor
tar vxf node_exporter*.tar.gz
cd node_exporter*/

echo "=> Create user/group"
sudo useradd -rs /bin/false node_exporter
sudo cp -f node_exporter $BIN_DIR
sudo chown node_exporter:node_exporter $BIN_DIR/node_exporter

echo "=> Create service file"
SERVICE_CONTENT="\n
[Unit]\n
Description=Node Exporter\n
After=network-online.target\n
\n
[Service]\n
User=node_exporter\n
Group=node_exporter\n
Type=simple\n
ExecStart=$BIN_DIR/node_exporter\n
\n
[Install]\n
WantedBy=multi-user.target\n
"
echo -e "$SERVICE_CONTENT" > /etc/systemd/system/node_exporter.service

echo "=> Start service"
systemctl daemon-reload
systemctl start node_exporter

# check service status
status=$(systemctl is-active node_exporter)
if [[ "$status" == "active" ]]; then
    status="${GREEN}$status${NC}"
else
    status="${RED}$status${NC}"
fi
echo -e "=> Service status: $status"

systemctl enable node_exporter

echo "=> Delete tmp files"
rm -rf /tmp/node_exporter*/
rm -rf /tmp/node_exporter*

echo "=> Installation complete!"