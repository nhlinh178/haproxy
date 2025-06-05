#!/bin/bash

# Cấu hình
echo " Cài đặt wget nếu chưa có..."
if ! command -v wget &> /dev/null; then
    echo "wget chưa được cài đặt. Đang cài đặt..."
    sudo yum install -y wget
else
    echo "wget đã được cài đặt."
fi 
echo "[*] Tạo user hệ thống cho node_exporter..."
if ! id "node_exporter" &>/dev/null; then
    sudo useradd --system --no-create-home --shell /bin/false node_exporter
else
    echo "User node_exporter đã tồn tại."
fi
echo "[*] Tải Node Exporter v1.8.2..."
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz

echo "[*] Giải nén và di chuyển binary..."
tar -xvf node_exporter-1.8.2.linux-amd64.tar.gz
cd node_exporter-1.8.2.linux-amd64
sudo cp node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo chmod +x /usr/local/bin/node_exporter
echo "[*] Tạo file service node_exporter..."
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter --collector.logind

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Kích hoạt và khởi động dịch vụ node_exporter..."
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "[*] Kiểm tra trạng thái dịch vụ:"
sudo systemctl status node_exporter --no-pager

echo "[✓] Cài đặt node_exporter hoàn tất!"
