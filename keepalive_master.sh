#!/bin/bash

# Kiểm tra tham số đầu vào
if [ -z "$VIP" ] || [ -z "$INTERFACE" ]; then
  echo "Vui lòng cung cấp giá trị VIP và INTERFACE."
  exit 1
fi

# Cài đặt Keepalived
yum install keepalived -y

# Sao lưu file cấu hình mặc định
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf-bak

# Tạo file cấu hình mới cho Keepalived
cat <<EOL > /etc/keepalived/keepalived.conf
vrrp_script chk_haproxy {
    script "killall -0 haproxy"
    interval 2 # every 2 seconds
    weight 2   # add 2 points if OK
}
vrrp_instance VI_1 {
    interface $INTERFACE
    state MASTER
    virtual_router_id 51
    priority 101
    virtual_ipaddress {
        $VIP
    }
    track_script {
        chk_haproxy
    }
}
EOL

# Khởi động lại dịch vụ Keepalived
systemctl restart keepalived

# Đảm bảo Keepalived khởi động cùng hệ thống
systemctl enable keepalived
