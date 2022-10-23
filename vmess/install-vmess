#!/bin/bash

# Created By HideSSH
# Some methods from 233boy/v2ray

apt-get update -y && apt-get install wget curl -y

check_if_running_as_root() {
  # If you want to run as another user, please modify $UID to be owned by this user
  if [[ "$UID" -ne '0' ]]; then
    echo "WARNING: The user currently executing this script is not root. You may encounter the insufficient privilege error."
    echo "Exiting..."
    sleep 1
    exit 1
  fi
}

check_if_tls_cert_exists() {
	if [ ! -e /data/tls.pem ] || [ ! -e /data/tls.key ]; then
		echo "TLS File on /data directory does not exists!"
		echo "Exiting..."
		sleep 2
		exit 1
	fi
}

init_input_config() {
	echo "Before start, make sure your domain has connected to CloudFlare (CF)."
	sleep 2

	echo -n "Domain Name : "
	read domain

	echo -n "Email Address : "
	read email

	echo "Fill the V2Ray/Vmess Port for TLS. Don't input 443, because that will used by Web Server."
	echo -n "V2Ray/VMess Port (TLS) : "
	read tlsPort

	echo -n "V2Ray/VMess Port (No-TLS) : "
	read ntlsPort

	echo -n "V2Ray/VMESS Websocket Path (Just alphanumeric. Don't Fill slash '/') : "
	read wsPath
}

install_nginx() {
	apt-get install nginx -y
	
	## backup nginx conf
	cp /etc/nginx/sites-available/default /etc/nginx/default.bak

	#cat >test.txt <<-EOF
	cat >/etc/nginx/sites-available/default <<-EOF
server {
	listen 443 ssl http2;
	listen [::]:443 http2;

	ssl_certificate /data/tls.pem;
	ssl_certificate_key /data/tls.key;
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers HIGH:!aNULL:!MD5;

	server_name ${domain};
	index index.html index.htm;
	root  /var/www/html;
	error_page 400 = /400.html;

	location /${wsPath}/
	{
		proxy_redirect off;
		proxy_pass http://127.0.0.1:${tlsPort};
		proxy_http_version 1.1;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header Upgrade \$http_upgrade;
		proxy_set_header Connection "upgrade";
		proxy_set_header Host \$http_host;
	}
}
server {
	listen 89;
	listen [::]:89;
	server_name ${domain};
	return 301 https://${domain}\$request_uri;
}
EOF
	systemctl restart nginx
}

install_v2ray() {
	# Install v2ray
	bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

	# Install GEOIP
	bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)

	# Make Server Config
	mkdir /etc/v2ray
	cat >/etc/v2ray/config.json <<-EOF
{
	"log": {
		"access": "/var/log/v2ray/access.log",
		"error": "/var/log/v2ray/error.log",
		"loglevel": "warning"
	},
	"inbounds": [
		{
			"port": ${tlsPort},
			"listen": "127.0.0.1",
			"tag": "vmess-in",
			"protocol": "vmess",
			"settings": {
				"clients": [
					{
						"id": "a79a1bec-196c-4f34-ac2a-8842233600c5",
						"level": 0,
						"alterId": 0
					}
				]
			},
			"streamSettings": {
				"network": "ws",
				"wsSettings": {
					"path": "/${wsPath}/"
				}
			}
		},
		{
			"port": ${ntlsPort},
			"protocol": "vmess",
			"tag": "vmess-ntls",
			"settings": {
				"clients": [
					{
						"id": "a79a1bec-196c-4f34-ac2a-8842233600c5",
						"level": 0,
						"alterId": 0
					}
				]
			},
			"streamSettings": {
				"network": "ws",
				"security": "none",
				"tlsSettings": {},
				"tcpSettings": {},
				"kcpSettings": {},
				"httpSettings": {},
				"wsSettings": {
					"path": "/${wsPath}/",
					"headers": {
						"Host": "${domain}"
					}
				},
				"quicSettings": {}
			}
		}
	],
	"outbounds": [
		{
			"protocol": "freedom",
			"settings": {},
			"tag": "direct"
		},
		{
			"protocol": "blackhole",
			"settings": {},
			"tag": "blocked"
		}
	],
	"dns": {
		"servers": [
			"https+local://dns-family.adguard.com/dns-query",
			"94.140.14.15",
			"94.140.15.16",
			"localhost"
		]
	},
	"routing": {
		"domainStrategy": "AsIs",
		"rules": [
			{
				"type": "field",
				"inboundTag": [
					"vmess-in"
				],
				"outboundTag": "direct"
			},
			{
				"type": "field",
				"ip": [
					"0.0.0.0/8",
					"10.0.0.0/8",
					"100.64.0.0/10",
					"169.254.0.0/16",
					"172.16.0.0/12",
					"192.0.0.0/24",
					"192.0.2.0/24",
					"192.168.0.0/16",
					"198.18.0.0/15",
					"198.51.100.0/24",
					"203.0.113.0/24",
					"::1/128",
					"fc00::/7",
					"fe80::/10"
				],
				"inboundTag": [
					"vmess-ntls"
				],
				"outboundTag": "blocked"
			}
		]
	}
}
EOF

	# Disable v2ray starter script
	systemctl disable v2ray

	# Create new v2ray starter script
	cat >/etc/systemd/system/stv2ray.service <<-EOF
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray -config /etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

	# Reload daemon
	systemctl daemon-reload
	systemctl enable stv2ray
	systemctl start stv2ray

	# Create client config
	cat >/etc/v2ray/client-tls.json <<-EOF
{
  "v": "2",
  "ps": "${domain}-tls",
  "add": "${domain}",
  "port": "443",
  "id": "a79a1bec-196c-4f34-ac2a-8842233600c5",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "${domain}",
  "path": "/${wsPath}/",
  "tls": "tls"
}
EOF

	cat >/etc/v2ray/client-ntls.json <<-EOF
{
  "v": "2",
  "ps": "${domain}-ntls",
  "add": "${domain}",
  "port": "80",
  "id": "a79a1bec-196c-4f34-ac2a-8842233600c5",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "${domain}",
  "path": "/${wsPath}/",
  "tls": ""
}
EOF

	# Get QR Code
	clear

	tlsBase=$(base64 /etc/v2ray/client-tls.json -w 0)
	ntlsBase=$(base64 /etc/v2ray/client-ntls.json -w 0)

	echo "TLS Config"
	echo "https://233boy.github.io/tools/qr.html#vmess://$tlsBase"

	echo "\n\nNo-TLS Config"
	echo "https://233boy.github.io/tools/qr.html#vmess://$ntlsBase"
}

apt-get update

apt-get install curl wget build-essential -y

clear

check_if_running_as_root

check_if_tls_cert_exists

init_input_config

install_nginx

install_v2ray
