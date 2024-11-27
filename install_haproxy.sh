#!/bin/bash

set -e  # Dừng script nếu có lỗi xảy ra

# Cài đặt các công cụ cần thiết
yum -y install net-tools
yum -y install epel-release
yum install -y wget socat vim nano htop iotop netstat telnet mtr nmon traceroute unzip zip nmap multitail
yum install -y iotop iftop wget

# Tải và cài đặt HAProxy
wget https://cbs.centos.org/kojifiles/packages/haproxy/2.2.29/1.el8s/x86_64/haproxy-2.2.29-1.el8s.x86_64.rpm
yum install -y haproxy-2.2.29-1.el8s.x86_64.rpm

# Kích hoạt và khởi động HAProxy
systemctl enable haproxy
systemctl start haproxy
systemctl status haproxy

# Cấu hình logging cho HAProxy
echo 'local0.*    /var/log/haproxy/haproxy-info.log
local0.notice /var/log/haproxy/haproxy-admin.log' > /etc/rsyslog.d/haproxy.conf

echo '$ModLoad imudp $UDPServerRun 514 $UDPServerAddress 127.0.0.1 ' >> /etc/rsyslog.conf

# Khởi động lại rsyslog để áp dụng cấu hình
systemctl restart rsyslog

# Cấu hình logrotate cho HAProxy
mv /etc/logrotate.d/haproxy /etc/logrotate.d/haproxy-bak || true
echo '/var/log/haproxy/*.log {
    daily
    rotate 7
    missingok
    copytruncate
    notifempty
    compress
    sharedscripts
    postrotate
        /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
        /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}' > /etc/logrotate.d/haproxy

# Cấu hình sysctl
echo 'net.ipv4.ip_nonlocal_bind = 1' >> /etc/sysctl.conf
sysctl -p

# Khởi động lại rsyslog và HAProxy
systemctl restart rsyslog
systemctl restart haproxy
