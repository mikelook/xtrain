#!/bin/bash
echo -e "\033[46;33m---------------系统配置---------------------------------\033[0m"
# 更新包列表并升级已安装的软件包
apt update --allow-releaseinfo-change
apt upgrade -y
apt-get update -y 
apt-get upgrade -y
# 安装 依赖
apt-get install vim -y
apt-get install touch -y
apt-get install cron -y 
apt-get install iptables -y 
apt-get install fail2ban -y 
apt-get install sudo -y 
apt-get install curl -y 
apt-get install update -y 
echo -e "\033[46;33m---------------xray配置---------------------------------\033[0m"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root
cd /usr/local/etc/xray
xray uuid > uuid
xray x25519 > key

# 设置 xray key 文件路径
# 输出抓取到的内容
echo -e "\033[46;33m---------------服务配置---------------------------------\033[0m"
mkdir -p /usr/local/etc/xray
key_file="/usr/local/etc/xray/key"

touch xtls.json
read -p "请输入uuid: " uuid
read -p "请输入域名带443: " domain
read -p "请输入服务器名1: " domain1
read -p "请输入服务器名2: " domain2
read -p "请输入服务器名3: " domain3
read -p "请输入服务器名4: " domain4
read -p "请输入privatekey: " key
# 判断 key 文件是否存在
if [ -f "$key_file" ]; then
  # 使用 grep 抓取第一行包含 "private key:" 后的内容
  key=$(head -n 1 "$key_file" | awk -F ': ' '{print $2}')
echo "抓取到的内容为: $s"
else
  echo "Key 文件不存在：$key_file"
fi

uuid=$(cat /usr/local/etc/xray/uuid)
config='{
  "log": {
    "loglevel": "info",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "api": {
    "tag": "api",
    "services": [
      "HandlerService",
      "LoggerService",
      "StatsService"
    ]
  },
  "stats": {},
  "policy": {
    "levels": {
      "0": {
        "statsUserUplink": true,
        "statsUserDownlink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true
    }
  },
  "dns": {
    "servers": [
      "https+local://cloudflare-dns.com/dns-query",
      "1.1.1.1",
      "1.0.0.1",
      "8.8.8.8",
      "8.8.4.4",
      "localhost"
    ]
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "'"$uuid"'",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": true,
          "dest": "'"$domain"'",
          "xver": 0,
          "maxTimeDiff": 0,
          "minClientVer": "",
          "serverNames": [
            "'"$domain1"'",
            "'"$domain2"'",
            "'"$domain3"'",
            "'"$domain4"'"    
          ],
          "privateKey": "'"$key"'",
          "shortIds": [
            "16",
            "1688",
            "168888",
            "16888888",
            "1688888888",
            "168888888888",
            "16888888888888",
            "1688888888888888"
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "domain": [
          "domain:iqiyi.com",
          "domain:video.qq.com",
          "domain:youku.com"
        ],
        "type": "field",
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "ip": [
          "geoip:cn",
          "geoip:private"
        ],
        "outboundTag": "blocked"
      },
      {
        "protocol": [
          "bittorrent"
        ],
        "type": "field",
        "outboundTag": "blocked"
      }
    ]
  }
}'
echo "$config" > /usr/local/etc/xray/xtls.json
echo "配置文件已生成。"
systemctl start xray@xtls.service
cat /usr/local/etc/xray/uuid
cat /usr/local/etc/xray/key
echo "systemctl status xray@xtls.service"

echo -e " \033[46;33m----------------BSR---------------------------------\033[0m"
#修改系统变量
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
#保存生效
sysctl -p
