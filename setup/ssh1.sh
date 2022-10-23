#!/bin/sh
#script auto installer SSH + SSLH
#created bye HideSSH.com and Kumpulanremaja.com
#OS Debian 9
apt-get update && apt-get upgrade -y
apt-get install wget curl -y

# Delete Acount SSH Expired
echo "================  Auto deleted Account Expired ======================"
wget -O /usr/local/bin/userdelexpired "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/userdelexpired" && chmod +x /usr/local/bin/userdelexpired

cd
# set time GMT +7 jakarta
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# initializing var
export DEBIAN_FRONTEND=noninteractive
MYIP=$(wget -qO- ipinfo.io/ip);
MYIP2="s/xxxxxxxxx/$MYIP/g";
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}');
source /etc/os-release
ver=$VERSION_ID

# detail nama perusahaan
country=ID
state=Semarang
locality=JawaTengah
organization=hidessh
organizationalunit=HideSSH
commonname=hidessh.com
email=admin@hidessh.com

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

cd
# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#upgrade packet penting
apt update -y
apt upgrade -y
apt dist-upgrade -y

#package tambahan
echo "================  install Package Tambahan Penting Lain nya ======================"
apt-get -y install gcc
apt-get -y install make
apt-get -y install cmake
apt-get -y install git
apt-get -y install wget
apt-get -y install screen
apt-get -y install unzip
apt-get -y install curl
apt-get -y install unrar
apt-get -y install dnsutils net-tools tcpdump grepcidr
apt-get install dsniff -y

# install tambahan
apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl neofetch git
echo "clear" >> .profile
echo "neofetch" >> .profile
echo "echo Mod by HIDESSH" >> .profil


echo "================  Setting OpenSSH ======================"
echo "========================================================="

# set locale SSH
cd
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 88' /etc/ssh/sshd_config
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart


echo "================  install and Setting Dropbear ======================"
echo "========================================================="

# install dropbear
cd
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=44/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 77 "/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/dropbear restart

# install squid3
echo "================  konfigurasi Squid3 ======================"
cd
apt-get -y install squid3
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/debian10/config/squid3"
sed -i $MYIP2 /etc/squid/squid.conf;
/etc/init.d/squid restart

echo "=================  install stunnel  ====================="
echo "========================================================="

# install stunnel
apt-get install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[openssh]
accept = 222
connect = 127.0.0.1:22
[openssh]
accept = 888
connect = 127.0.0.1:88
[dropbear]
accept = 444
connect = 127.0.0.1:44
[dropbear]
accept = 777
connect = 127.0.0.1:77
[websocketpython]
accept = 99
connect = 30000
[openvpn]
accept = 992
connect = 127.0.0.1:1194

END

echo "=================  membuat Sertifikat OpenSSL ======================"
echo "========================================================="
#membuat sertifikat
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart


#install sslh
apt-get install sslh -y

#konfigurasi
wget -O /etc/default/sslh "https://raw.githubusercontent.com/idtunnel/sslh/master/sslh-conf"
service sslh restart

cd
# common password debian 
wget -O /etc/pam.d/common-password "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/common-password-deb9"
chmod +x /etc/pam.d/common-password

echo "=================  Install badVPn (VC and Game) ======================"
echo "========================================================="

cd
# buat directory badvpn
echo "================= Auto Installer Disable badVPN V 3  ======================"
# install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://adiscript.vercel.app/vpn/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500' /etc/rc.local
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500

#install bbr dan optimasi kernel
cd
wget https://raw.githubusercontent.com/4hidessh/cuy1/main/bbr.sh && chmod +x bbr.sh && ./bbr.sh
wget https://raw.githubusercontent.com/4hidessh/cuy1/main/set-br.sh && chmod +x set-br.sh && ./set-br.sh

#echo "=================  Install NGINX======================"
#echo "========================================================="

# install webserver
#apt -y install nginx
3cd
#rm /etc/nginx/sites-enabled/default
#rm /etc/nginx/sites-available/default
#wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/fisabiliyusri/test1/main/nginx.conf"
#mkdir -p /home/vps/public_html
#echo "<pre>Setup Mod By SL</pre>" > /home/vps/public_html/index.html
#wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/fisabiliyusri/test1/main/vps.conf"
#/etc/init.d/nginx restart

#Matikan OpenVPN
#wget https://raw.githubusercontent.com/fisabiliyusri/test1/main/install/vpn.sh &&  chmod +x vpn.sh && ./vpn.sh

# buat directory badvpn
#cd /usr/bin
#mkdir build
#cd build
#wget https://github.com/ambrop72/badvpn/archive/1.999.130.tar.gz
#tar xvzf 1.999.130.tar.gz
#cd badvpn-1.999.130
#cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1 -DBUILD_UDPGW=1
#make install
#make -i install

# auto start badvpn single port
#sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 100' /etc/rc.local
#screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 100 &
#cd

# permition
#chmod +x /usr/local/bin/badvpn-udpgw
#chmod +x /usr/local/share/man/man7/badvpn.7
#chmod +x /usr/local/bin/badvpn-tun2socks
#chmod +x /usr/local/share/man/man8/badvpn-tun2socks.8
#chmod +x /usr/bin/build
#chmod +x /etc/rc.local

# Custom Banner SSH
cd
echo "================  Banner ======================"
wget -O /etc/issue.net "https://github.com/idtunnel/sshtunnel/raw/master/debian9/banner-custom.conf"
chmod +x /etc/issue.net

echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
echo "DROPBEAR_BANNER="/etc/issue.net"" >> /etc/default/dropbear

# install fail2ban
apt-get -y install fail2ban
service fail2ban restart
cd

# Instal DDOS Flate
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip -O ddos.zip
unzip ddos.zip
cd ddos-deflate-master
./install.sh

cd
# iptables-persistent
echo "================  Firewall ======================"
apt install iptables-persistent -y
wget https://raw.githubusercontent.com/4hidessh/hidessh/main/security/torrent
chmod +x torrent
bash torrent
netfilter-persistent save
netfilter-persistent reload 


# download script

echo "================  install Menu tambahan ======================"
cd /usr/bin
wget -O addhost "https://raw.githubusercontent.com/4hidessh/cuy1/main/tambah/addhost1.sh"
wget -O menu "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/menu.sh"
wget -O usernew "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/usernew.sh"
wget -O trial "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/trial.sh"
wget -O hapus "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/hapus.sh"
wget -O cek "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/user-login.sh"
wget -O member "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/user-list.sh"
wget -O jurus69 "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/restart.sh"
wget -O speedtest "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/info.sh"
wget -O about "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/about.sh"
wget -O delete "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/delete.sh"

#permisiion
chmod +x menu
chmod +x usernew
chmod +x trial
chmod +x hapus
chmod +x cek
chmod +x member
chmod +x jurus69
chmod +x speedtest
chmod +x info
chmod +x about
chmod +x delete
chmod +x addhost

# autoreboot 12 jam

echo "================  Auto Reboot ======================"
echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot
echo "0 5 * * * root clear-log && reboot" >> /etc/crontab

# remove unnecessary files
apt -y autoclean
apt -y remove --purge unscd
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove bind9*;
apt-get -y remove sendmail*
apt -y autoremove

# finishing
cd
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500

#hapus
rm -rf ssh1.sh
