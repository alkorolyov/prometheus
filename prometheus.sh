#!/bin/bash

############## PROMETHEUS_INSTALL.sh #######################

sudo apt-get -qq update

# create prometheus user:group
sudo useradd -rs /bin/false prometheus

# Download and unpack latest prometheus to /tmp
cd /tmp
wget $(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "browser_download_url.*linux-amd64" | cut -d '"' -f 4)
tar vxf prometheus*.tar.gz
cd prometheus*/

# edit config
CONFIG_CONTENT="
global:\n
  scrape_interval: 5s\n
\n
scrape_configs:\n
  - job_name: vm_test_node\n
    static_configs:\n
      - targets: ['localhost:9100', 'localhost:9090']\n
\n
remote_write:\n
- url: https://prometheus-prod-22-prod-eu-west-3.grafana.net/api/prom/push\n
  basic_auth:\n
    username: 1120366\n
    password: eyJrIjoiMDRhNGYwMDU1ODljMGU2M2I1MWM5YTgyMDg1MGRiZWM5MjY3M2ExYiIsIm4iOiJtaWNyby1nY3AiLCJpZCI6OTEyNzQ2fQ==\n
"

echo -e $CONFIG_CONTENT > prometheus.yml

# move files and change ownerships
mv prometheus /usr/local/bin
mv promtool /usr/local/bin
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

# create dirs
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

mv consoles /etc/prometheus
mv console_libraries /etc/prometheus
mv prometheus.yml /etc/prometheus
chown prometheus:prometheus /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
chown -R prometheus:prometheus /var/lib/prometheus

SERVICE_CONTENT="[Unit]\n
Description=Prometheus\n
Wants=network-online.target\n
After=network-online.target\n
\n
[Service]\n
User=prometheus\n
Group=prometheus\n
Type=simple\n
ExecStart=/usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/  --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries\n
\n
[Install]\n
WantedBy=multi-user.target\n
"

sudo bash -c "echo -e '$SERVICE_CONTENT' > /etc/systemd/system/prometheus.service"

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl status prometheus
sudo systemctl enable prometheus

sudo ufw allow 9090/tcp
sudo ufw allow 9100/tcp

# delete tmp files
cd /tmp
rm -rf /tmp/prometheus*/
rm -rf /tmp/prometheus*
