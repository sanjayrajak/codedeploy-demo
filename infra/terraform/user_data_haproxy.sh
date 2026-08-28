#!/bin/bash
set -euxo pipefail

# ---------------------------------------------------------------
# User data for HAProxy instance — Amazon Linux 2023
# Mimics production HAProxy setup in front of Kestrel API servers
# ${app_name}, ${server1_ip}, ${server2_ip} are Terraform template vars
# ---------------------------------------------------------------

dnf update -y
dnf install -y haproxy

# ---------------------------------------------------------------
# Write HAProxy config
# ---------------------------------------------------------------
cat > /etc/haproxy/haproxy.cfg << 'EOF'
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log         /dev/log local0
    log         /dev/log local1 notice
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4096
    user        haproxy
    group       haproxy
    daemon
    # Runtime API — allows CodeDeploy hooks to drain/restore servers without config reload
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners

#---------------------------------------------------------------------
# Default settings
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option                  http-server-close
    option                  forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

#---------------------------------------------------------------------
# Stats page — http://<haproxy-ip>:8404/stats
#---------------------------------------------------------------------
frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats show-legends
    stats show-node
    stats auth admin:sandbox123

#---------------------------------------------------------------------
# Frontend — accepts incoming HTTP on port 80
#---------------------------------------------------------------------
frontend http_front
    bind *:80
    default_backend api_servers

#---------------------------------------------------------------------
# Backend — Kestrel API servers with health checks
#---------------------------------------------------------------------
backend api_servers
    balance     roundrobin
    option      httpchk
    http-check  send meth GET uri /health
    http-check  expect status 200

    # Servers are referenced by private IP (stable within VPC)
    server api1 ${server1_ip}:5000 check inter 10s fall 3 rise 2
    server api2 ${server2_ip}:5000 check inter 10s fall 3 rise 2
EOF

# ---------------------------------------------------------------
# Enable and start HAProxy
# ---------------------------------------------------------------
systemctl enable haproxy
systemctl start haproxy

echo "HAProxy setup complete for ${app_name}"
echo "Stats: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8404/stats"
