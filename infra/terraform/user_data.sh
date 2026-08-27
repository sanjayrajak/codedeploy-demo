#!/bin/bash
set -euxo pipefail

# ---------------------------------------------------------------
# User data — runs once on first boot for Amazon Linux 2023
# ${region} and ${app_name} are Terraform templatefile variables.
# All other bash variables use $VAR (no braces) to avoid conflict.
# ---------------------------------------------------------------

# System update
dnf update -y

# ---------------------------------------------------------------
# Install .NET 8 and .NET 9 runtimes
# ---------------------------------------------------------------
dnf install -y dotnet-runtime-8.0 dotnet-runtime-9.0

# ---------------------------------------------------------------
# Install CodeDeploy agent for Amazon Linux 2023
# The generic "auto" installer script doesn't support AL2023.
# Use the direct .noarch.rpm from the regional S3 bucket.
# ---------------------------------------------------------------
dnf install -y ruby wget

cd /tmp
wget -q "https://aws-codedeploy-${region}.s3.${region}.amazonaws.com/latest/codedeploy-agent.noarch.rpm"
dnf install -y ./codedeploy-agent.noarch.rpm

# The rpm installs a SysV init script — use service to start it
service codedeploy-agent start

# ---------------------------------------------------------------
# Create app user and directories
# ---------------------------------------------------------------
useradd --system --no-create-home --shell /bin/false kestrel || true
mkdir -p /opt/helloapi
chown kestrel:kestrel /opt/helloapi

# ---------------------------------------------------------------
# Install the systemd unit for the Kestrel app
# (will be started on first CodeDeploy deployment)
# ---------------------------------------------------------------
cat > /etc/systemd/system/helloapi.service << 'UNIT'
[Unit]
Description=HelloApi .NET Kestrel Service (${app_name})
After=network.target

[Service]
User=kestrel
WorkingDirectory=/opt/helloapi
ExecStart=/usr/bin/dotnet /opt/helloapi/HelloApi.dll
Restart=on-failure
RestartSec=5
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload

echo "Bootstrap complete for ${app_name}"
