#!/bin/bash

set -e

FRP_VERSION="0.63.0"
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "不支持的系统架构: $ARCH"
    exit 1
fi

# 1. 下载并安装 frpc
WORK_DIR="/tmp/frp_setup"
mkdir -p $WORK_DIR
cd $WORK_DIR

echo "正在下载 frp v${FRP_VERSION} ..."
wget https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${ARCH}.tar.gz

echo "正在解压..."
tar -xzf frp_${FRP_VERSION}_linux_${ARCH}.tar.gz

echo "安装 frpc 到 /usr/local/bin"
cp frp_${FRP_VERSION}_linux_${ARCH}/frpc /usr/local/bin/frpc
chmod +x /usr/local/bin/frpc

# 2. 交互式输入配置参数
read -p "请输入 frps 服务器地址 (serverAddr): " SERVER_ADDR
read -p "请输入 frps 服务器端口 (serverPort) [默认7000]: " SERVER_PORT
read -p "请输入认证 token: " TOKEN
read -p "请输入穿透名称 (name): " NAME
read -p "请输入本地服务端口 (localPort): " LOCAL_PORT
read -p "请输入远程映射端口 (remotePort): " REMOTE_PORT

SERVER_PORT=${SERVER_PORT:-7000}

echo "============== 配置预览 =============="
echo "serverAddr = $SERVER_ADDR"
echo "serverPort = $SERVER_PORT"
echo "token = $TOKEN"
echo "name = $NAME"
echo "localPort = $LOCAL_PORT"
echo "remotePort = $REMOTE_PORT"
echo "======================================"

read -p "确认生成配置并启动? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "操作已取消。"
    exit 0
fi

# 3. 生成配置文件
mkdir -p /etc/frp

cat > /etc/frp/frpc.toml <<EOF
serverAddr = "$SERVER_ADDR"
serverPort = $SERVER_PORT
auth.token = "$TOKEN"

[[proxies]]
name = "$NAME"
type = "tcp"
localIP = "127.0.0.1"
localPort = $LOCAL_PORT
remotePort = $REMOTE_PORT
EOF

# 4. 生成 systemd 服务
cat > /etc/systemd/system/frpc.service <<EOF
[Unit]
Description=frpc service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/frpc -c /etc/frp/frpc.toml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 5. 启动并设置开机自启
systemctl daemon-reload
systemctl enable frpc
systemctl restart frpc

echo "frpc 已启动，当前状态："
systemctl status frpc --no-pager

# 6. 清理临时文件
rm -rf $WORK_DIR

echo "部署完成！"
