#!/bin/bash
###### node_exporter service ########

echo "=> Start installation of node_exporter service"

if [[ $UID -ne 0 ]]; then
    echo "Installation should be run as root. Use 'sudo bash ./node_exporter.sh'"
    exit
fi

echo "=> Download and extract latest node_exporter"
cd /tmp
wget -q $(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "browser_download_url.*linux-amd64" | cut -d '"' -f 4)
tar vxf node_exporter*.tar.gz
cd node_exporter*/

echo "=> Create user/group"
sudo useradd -rs /bin/false node_exporter
sudo cp -f node_exporter /usr/local/bin
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

echo "=> Create service file"
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
bash -c "echo -e '$SERVICE' > /etc/systemd/system/node_exporter.service"

echo "=> Start service"
systemctl daemon-reload
systemctl start node_exporter
# sudo systemctl status node_exporter
status=$(systemctl is-active node_exporter)
echo "=> Service status: '$status'"
systemctl enable node_exporter

echo "=> Delete tmp files"
rm -rf /tmp/node_exporter*/
rm -rf /tmp/node_exporter*

echo "=> Installation complete!"

echo "=> Complete"
