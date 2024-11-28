#!/bin/bash

# Tham số đầu vào
echo "Received DOMAIN: $DOMAIN"
echo "Received IPSERVER1="$IPSERVER1"
echo "Received IPSERVER2="$IPSERVER2"
# Kiểm tra và tạo thư mục cert nếu chưa tồn tại
if [ ! -d "/etc/haproxy/certs" ]; then
   sudo mkdir -p /etc/haproxy/certs
fi
# Kiểm tra và tạo file cert nếu chưa tồn tại
if [ ! -d "/etc/haproxy/certs/${DOMAIN}.pem" ]; then
   sudo touch /etc/haproxy/certs/${DOMAIN}.pem
fi
# Tạo file cấu hình HAProxy
echo "
# Global settings
global
    log /dev/log local0
    log /dev/log local1 notice    
    log 127.0.0.1:514 local0
    chroot /var/lib/haproxy
    pidfile /var/run/haproxy.pid
    user haproxy
    group haproxy
    daemon
    nbproc 1
    ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11
    stats socket /var/lib/haproxy/stats

defaults
    log global
    mode http
    option dontlognull
    option http-server-close
    option redispatch
    retries 3
    timeout http-request 15s
    timeout queue 30s
    timeout connect 30s
    timeout client 300s
    timeout server 300s
    timeout http-keep-alive 90s
    timeout check 30s
    maxconn 45000

listen stats
    bind *:8999 interface ens32
    mode http
    stats enable
    stats uri /haproxy
    stats realm HAProxy\ Statistics
    stats auth isofh:HA@ISOFH

frontend https_in
    bind *:443 ssl crt /etc/haproxy/certs/${DOMAIN}.pem
    mode http
    log global
    option httplog
    timeout http-request 60m

    acl host_api_his_pdf hdr(host) -i api-his.domain
    acl path_pdf_api_his url_beg /pdf
    use_backend backend_pdf_api_his if host_api_his_pdf path_pdf_api_his

    acl host_api_his hdr(host) -i api-his.domain
    use_backend backend_api_his if host_api_his

backend backend_api_his
    mode http
    balance roundrobin
    option httpclose
    option forwardfor
    cookie JSESSIONID prefix
    server server1 $IPSERVER1:2301 check cookie server1
    server server2 $IPSERVER2:2301 check cookie server2

backend backend_pdf_api_his
    mode http
    http-request replace-uri ^/pdf/(.*) /\1
    balance roundrobin
    option httpclose
    option forwardfor
    cookie JSESSIONID prefix
    server server1 $IPSERVER1:2200 check cookie server1
    server server2 $IPSERVER2:2200 check cookie server2
" > /etc/haproxy/haproxy.cfg

# Restart HAProxy service
echo "Restarting HAProxy..."
systemctl restart haproxy
