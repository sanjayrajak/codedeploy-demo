#!/bin/bash
set -euxo pipefail

# ---------------------------------------------------------------
# User data — runs once on first boot for Amazon Linux 2023
# Installs: .NET runtime, CodeDeploy agent
# ---------------------------------------------------------------

REGION="${region}"
APP_NAME="${app_name}"

# System update
dnf update -y

# ---------------------------------------------------------------
# Install .NET 8 runtime (change version to match your app)
# ---------------------------------------------------------------
dnf install -y dotnet-runtime-8.0

# ---------------------------------------------------------------
# Install CodeDeploy agent
# ---------------------------------------------------------------
dnf install -y ruby wget

cd /tmp
wget -q "https://aws-codedeploy-$REGION.s3.$REGION.amazonaws.com/latest/install"
chmod +x ./install
./install auto -v latest

systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# ---------------------------------------------------------------
# Create app user and directories
# ---------------------------------------------------------------
useradd --system --no-create-home --shell /bin/false kestrel || true
mkdir -p /opt/helloapi
chown kestrel:kestrel /opt/helloapi

# ---------------------------------------------------------------
# Create a placeholder systemd unit (overwritten on first deploy)
# ---------------------------------------------------------------
cat > /etc/systemd/system/helloapi.service << 'EOF'
[Unit]
Description=HelloApi .NET Kestrel Service
After=network.target

[Service]
User=kestrel
WorkingDirectory=/opt/helloapi
ExecStart=/usr/bin/dotnet /opt/helloapi/HelloApi.dll
Restart=on-failure
RestartSec=5
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

# Hardening
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
# Don't start yet — first deploy will start it

echo "Bootstrap complete for $APP_NAME"
