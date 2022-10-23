#!/bin/bash 

#script auto installer SSH + SSLH
#created bye HideSSH.com and Kumpulanremaja.com
#OS Ubuntu and debian

# initializing var
export DEBIAN_FRONTEND=noninteractive
MYIP=$(wget -qO- icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}');
source /etc/os-release
ver=$VERSION_ID

#detail nama perusahaan
country=ID
state=Semarang
locality=JawaTengah
organization=hidessh
organizationalunit=HideSSH
commonname=hidessh.com
email=admin@hidessh.com

# simple password minimal
wget -q -O /etc/pam.d/common-password "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/password"
chmod +x /etc/pam.d/common-password

# Delete Acount SSH Expired
echo "================  Auto deleted Account Expired ======================"
wget -O /usr/local/bin/userdelexpired "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/userdelexpired" && chmod +x /usr/local/bin/userdelexpired

# go to root
cd

# Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#update
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y

# install wget and curl
apt -y install wget curl

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

# install
apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl neofetch git lsof
apt install iptables-persistent -y
echo "clear" >> .profile
echo "neofetch" >> .profile

# install webserver
apt -y install nginx
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -q -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/nginx.conf"
mkdir -p /home/vps/public_html
wget -q -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/vps.conf"
/etc/init.d/nginx restart

# install badvpn
cd
wget -q -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500' /etc/rc.local
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500

# setting port ssh
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 88' /etc/ssh/sshd_config
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

# install dropbear
apt -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=44/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 77"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/dropbear restart

# install squid
cd
apt -y install squid3
wget -q -O /etc/squid/squid.conf "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/squid3.conf"
sed -i $MYIP2 /etc/squid/squid.conf

# setting vnstat
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://humdi.net/vnstat/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install
cd
vnstat -u -i $NET
sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz
rm -rf /root/vnstat-2.6

# install stunnel
apt install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 444
connect = 127.0.0.1:44

[openssh]
accept = 222
connect = 127.0.0.1:22

[dropbear]
accept = 777
connect = 127.0.0.1:77

[oenssh]
accept = 888
connect = 127.0.0.1:88

[openvpn]
accept = 442
connect = 127.0.0.1:1194

END

# make a certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart

#sshws
apt -y install python
apt -y install tmux
apt -y install ruby
gem install lolcat
apt -y install figlet
wget -q -O /usr/local/bin/edu-proxy https://raw.githubusercontent.com/4hidessh/hidessh/main/setup/websocket.py
chmod +x /usr/local/bin/edu-proxy

# Installing Service
cat > /etc/systemd/system/edu-proxy.service << END
[Unit]
Description=Autoscript by HideSSH
Documentation=https://hidessh.com
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/python -O /usr/local/bin/edu-proxy 2082
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable edu-proxy
systemctl restart edu-proxy

#OpenVPN
#wget -q https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/vpn.sh &&  chmod +x vpn.sh && ./vpn.sh

# install fail2ban
apt -y install fail2ban

# Instal DDOS Flate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
clear
echo; echo 'Installing DOS-Deflate 0.6'; echo
echo; echo -n 'Downloading source files...'
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
echo -n '.'
wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
echo -n '.'
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
echo -n '.'
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
echo '...done'
echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
echo '.....done'
echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/ddos/ddos.conf'
echo 'Please send in your comments and/or suggestions to zaf@vsnl.com'

#install sslh
apt-get install sslh -y

#konfigurasi
wget -O /etc/default/sslh "https://raw.githubusercontent.com/idtunnel/sslh/master/sslh-conf"
service sslh restart

# Custom Banner SSH
echo "================  Banner ======================"
wget -O /etc/issue.net "https://github.com/idtunnel/sshtunnel/raw/master/debian9/banner-custom.conf"
chmod +x /etc/issue.net

echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
echo "DROPBEAR_BANNER="/etc/issue.net"" >> /etc/default/dropbear

# blockir torrent
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# download script
cd /usr/bin
wget -q -O add-host "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/add-host.sh"
wget -q -O about "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/about.sh"
wget -q -O menu "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/menu.sh"
wget -q -O usernew "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/usernew.sh"
wget -q -O trial "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/trial.sh"
wget -q -O hapus "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/hapus.sh"
wget -q -O member "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/member.sh"
wget -q -O delete "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/delete.sh"
wget -q -O cek "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/cek.sh"
wget -q -O restart "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/restart.sh"
wget -q -O speedtest "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/speedtest_cli.py"
wget -q -O info "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/info.sh"
wget -q -O ram "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/ram.sh"
wget -q -O renew "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/renew.sh"
wget -q -O autokill "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/autokill.sh"
wget -q -O ceklim "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/ceklim.sh"
wget -q -O tendang "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/tendang.sh"
wget -q -O clear-log "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/clear-log.sh"
wget -q -O change-port "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/change.sh"
wget -q -O port-ovpn "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/port-ovpn.sh"
wget -q -O port-ssl "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/port-ssl.sh"
wget -q -O port-wg "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/port-wg.sh"
wget -q -O port-tr "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/port-tr.sh"
wget -q -O port-sstp "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/port-sstp.sh"
wget -q -O port-squid "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/port-squid.sh"
wget -q -O port-ws "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/port-ws.sh"
wget -q -O port-vless "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/port-vless.sh"
wget -q -O wbmn "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/webmin.sh"
wget -q -O xp "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/xp.sh"
wget -q -O kernel-updt "https://raw.githubusercontent.com/ZzZzZzZXCoo/no/main/kernel-update.sh"
chmod +x add-host
chmod +x menu
chmod +x usernew
chmod +x trial
chmod +x hapus
chmod +x member
chmod +x delete
chmod +x cek
chmod +x restart
chmod +x speedtest
chmod +x info
chmod +x about
chmod +x autokill
chmod +x tendang
chmod +x ceklim
chmod +x ram
chmod +x renew
chmod +x clear-log
chmod +x change-port
chmod +x port-ovpn
chmod +x port-ssl
chmod +x port-wg
chmod +x port-sstp
chmod +x port-tr
chmod +x port-squid
chmod +x port-ws
chmod +x port-vless
chmod +x wbmn
chmod +x xp
chmod +x kernel-updt
echo "0 5 * * * root clear-log && reboot" >> /etc/crontab
echo "0 0 * * * root xp" >> /etc/crontab
# remove unnecessary files
cd
apt autoclean -y
apt -y remove --purge unscd
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove bind9*;
apt-get -y remove sendmail*
apt autoremove -y
# finishing
cd
chown -R www-data:www-data /home/vps/public_html
/etc/init.d/nginx restart
/etc/init.d/openvpn restart
/etc/init.d/cron restart
/etc/init.d/ssh restart
/etc/init.d/dropbear restart
/etc/init.d/fail2ban restart
/etc/init.d/stunnel4 restart
/etc/init.d/vnstat restart
/etc/init.d/squid restart
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500
history -c
echo "unset HISTFILE" >> /etc/profile

cd
rm -f /root/key.pem
rm -f /root/cert.pem
rm -f /root/ssh-vpn.sh

# finihsing
clear
