#!/bin/bash

# Tham số
echo "Received VIP: $VIP"
echo "Received INTERFACE: $INTERFACE"
echo "Received KEEPALIVED_STATE: $KEEPALIVED_STATE"

# Tạo cấu hình Keepalived cho node2
if [ "$KEEPALIVED_STATE" == "MASTER" ]; then
    echo '
vrrp_script chk_haproxy {
    script "killall -0 haproxy"
    interval 2
    weight 2
}
vrrp_instance VI_1 {
    interface '${INTERFACE}'
    state MASTER
    virtual_router_id 51
    priority 101
    virtual_ipaddress {
        '${VIP}'
    }
    track_script {
        chk_haproxy
    }
}' > /etc/keepalived/keepalived.conf
elif [ "$KEEPALIVED_STATE" == "BACKUP" ]; then
    echo '
vrrp_script chk_haproxy {
    script "killall -0 haproxy"
    interval 2
    weight 2
}
vrrp_instance VI_1 {
    interface '${INTERFACE}'
    state BACKUP
    virtual_router_id 51
    priority 100
    virtual_ipaddress {
        '${VIP}'
    }
    track_script {
        chk_haproxy
    }
}' > /etc/keepalived/keepalived.conf
else
    echo "Invalid KEEPALIVED_STATE value. Please use MASTER or BACKUP."
    exit 1
fi

# Khởi động lại Keepalived
systemctl restart keepalived
