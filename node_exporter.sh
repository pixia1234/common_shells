#!/bin/bash

set -e

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

# 获取最新版本
LATEST_VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
echo "检测到最新版本: $LATEST_VERSION"

FILENAME="node_exporter-${LATEST_VERSION}.linux-${ARCH_TYPE}.tar.gz"
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${LATEST_VERSION}/${FILENAME}"

WORK_DIR="/tmp/node_exporter_setup"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "开始下载: $DOWNLOAD_URL"
curl -LO "$DOWNLOAD_URL"

echo "解压文件..."
tar -xzf "$FILENAME"

# 移动可执行文件
echo "移动 node_exporter 到 /usr/local/bin"
mv node_exporter-${LATEST_VERSION}.linux-${ARCH_TYPE}/node_exporter /usr/local/bin/node_exporter
chmod +x /usr/local/bin/node_exporter

# 清理临时文件
rm -rf "$WORK_DIR"

# 配置 systemd 服务
cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/node_exporter --web.listen-address=127.0.0.1:9100
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启动并设置开机自启
systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter

# 查看服务状态
systemctl status node_exporter --no-pager

echo "Node Exporter 已成功安装并启动！"
