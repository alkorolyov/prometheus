#!/bin/bash
###### node_exporter service ########

# download latest node_exporter
cd /tmp
wget $(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "browser_download_url.*linux-amd64" | cut -d '"' -f 4)

tar vxf node_exporter*.tar.gz
cd node_exporter*/

# create user/group
sudo useradd -rs /bin/false node_exporter
sudo cp node_exporter /usr/local/bin
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

SERVICE="\n
[Unit]\n
Description=Node Exporter\n
After=network-online.target\n
\n
[Service]\n
User=node_exporter\n
Group=node_exporter\n
Type=simple\n
ExecStart=/usr/local/bin/node_exporter\n
\n
[Install]\n
WantedBy=multi-user.target\n
"

sudo bash -c "echo -e '$SERVICE' > /etc/systemd/system/node_exporter.service"

sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl status node_exporter.service
sudo systemctl enable node_exporter

rm -rf /tmp/node_exporter*/
rm -rf /tmp/node_exporter*
