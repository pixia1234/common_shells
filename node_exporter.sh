#!/bin/bash

set -e

INSTALL_DIR="$HOME/prometheus"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH_TYPE="amd64"
        ;;
    aarch64)
        ARCH_TYPE="arm64"
        ;;
    armv5*)
        ARCH_TYPE="armv5"
        ;;
    armv6*)
        ARCH_TYPE="armv6"
        ;;
    armv7*)
        ARCH_TYPE="armv7"
        ;;
    mips)
        ARCH_TYPE="mips"
        ;;
    mips64)
        ARCH_TYPE="mips64"
        ;;
    mips64le)
        ARCH_TYPE="mips64le"
        ;;
    mipsle)
        ARCH_TYPE="mipsle"
        ;;
    ppc64)
        ARCH_TYPE="ppc64"
        ;;
    ppc64le)
        ARCH_TYPE="ppc64le"
        ;;
    riscv64)
        ARCH_TYPE="riscv64"
        ;;
    s390x)
        ARCH_TYPE="s390x"
        ;;
    *)
        echo "不支持的架构: $ARCH"
        exit 1
        ;;
esac
LATEST_VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
echo "检测到最新版本: $LATEST_VERSION"
FILENAME="node_exporter-${LATEST_VERSION}.linux-${ARCH_TYPE}.tar.gz"
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${LATEST_VERSION}/${FILENAME}"
echo "开始下载: $DOWNLOAD_URL"
curl -LO "$DOWNLOAD_URL"

# 5. 解压
tar -xzf "$FILENAME"
rm -f "$FILENAME"
chmod +x "${INSTALL_DIR}/node_exporter-${LATEST_VERSION}.linux-${ARCH_TYPE}/node_exporter"
# 6. 配置systemd服务
cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=/root/prometheus/node_exporter-${LATEST_VERSION}.linux-${ARCH_TYPE}/node_exporter --web.listen-address=127.0.0.1:9100
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

chmod +x "/root/prometheus/node_exporter-${LATEST_VERSION}.linux-${ARCH_TYPE}/node_exporter"

# 7. 重载systemd并启动服务
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# 8. 查看服务状态
systemctl status node_exporter --no-pager
