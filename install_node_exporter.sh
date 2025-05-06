#!/bin/bash

# Cấu hình
NODE_EXPORTER_VERSION="1.8.2"
NODE_EXPORTER_USER="node_exporter"
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

echo "[*] Tạo user hệ thống cho node_exporter..."
sudo useradd --system --no-create-home --shell /bin/false $NODE_EXPORTER_USER

echo "[*] Tải Node Exporter v${NODE_EXPORTER_VERSION}..."
wget $DOWNLOAD_URL -O node_exporter.tar.gz

echo "[*] Giải nén và di chuyển binary..."
tar -xvf node_exporter.tar.gz
cd node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64
sudo mv node_exporter /usr/local/bin/

echo "[*] Dọn dẹp..."
cd ..
rm -rf node_exporter*

echo "[*] Tạo file service node_exporter..."
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=${NODE_EXPORTER_USER}
Group=${NODE_EXPORTER_USER}
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter --collector.logind

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Kích hoạt và khởi động dịch vụ node_exporter..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "[*] Kiểm tra trạng thái dịch vụ:"
sudo systemctl status node_exporter --no-pager

echo "[✓] Cài đặt node_exporter hoàn tất!"
