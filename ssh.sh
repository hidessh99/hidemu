#!/bin/sh
#script auto installer SSH + VPN LT2P/IPSec PSK
#created bye HideSSH.com and Kumpulanremaja.com
#OS Debian 9



#auto installer SSH + Dropbear +Stunnel + SSLH Multi Port 


# Delete Acount SSH Expired
echo "================  Auto deleted Account Expired ======================"
wget -O /usr/local/bin/userdelexpired "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/userdelexpired" && chmod +x /usr/local/bin/userdelexpired

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0'`;
MYIP2="s/xxxxxxxxx/$MYIP/g";

# detail nama perusahaan
country=ID
state=Semarang
locality=JawaTengah
organization=hidessh
organizationalunit=HideSSH
commonname=hidessh.com
email=admin@hidessh.com

cd
# disable ipv6
echo "=================  Disable IPv6 ======================"
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

cd
# set time GMT +7 jakarta
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale SSH
echo "=================  Setting Port SSH ======================"
cd
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 80' /etc/ssh/sshd_config
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

echo "================  install Dropbear ======================"
echo "========================================================="

# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=44/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 77 "/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/ssh restart
/etc/init.d/dropbear restart

echo "=================  install Squid3  ======================"
echo "========================================================="

# setting dan install vnstat debian 9 64bit
echo "=================  Penggunaan Bandhwite ======================"
apt-get -y install vnstat
systemctl start vnstat
systemctl enable vnstat
chkconfig vnstat on
chown -R vnstat:vnstat /var/lib/vnstat

# install squid3
echo "================  konfigurasi Squid3 ======================"
cd
apt-get -y install squid3
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/squid3.conf"
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
[dropbear]
accept = 222
connect = 127.0.0.1:22
[dropbear]
accept = 444
connect = 127.0.0.1:44
[dropbear]
accept = 777
connect = 127.0.0.1:77
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

#install Dns Server
echo "=================  DNS Server ======================"
apt-get install resolvconf -y
wget -O /etc/resolvconf/resolv.conf.d/head "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/dns" && chmod +x /etc/resolvconf/resolv.conf.d/head


#install sslh
echo "=================  Install Multi Port ======================"
apt-get install sslh -y

#konfigurasi
wget -O /etc/default/sslh "https://raw.githubusercontent.com/idtunnel/sslh/master/sslh-conf"
service sslh restart

cd
# common password debian 
wget -O /etc/pam.d/common-password "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/common-password-deb9"
chmod +x /etc/pam.d/common-password

cd
echo "================  install Package Tambahan Penting Lain nya ======================"
apt-get -y install gcc
apt-get -y install make
apt-get install cmake -y
apt-get -y install git
apt-get -y install wget
apt-get -y install screen
apt-get -y install unzip
apt-get -y install curl
apt-get -y install unrar



cd

# buat directory badvpn
cd /usr/bin
mkdir build
cd build
wget https://github.com/ambrop72/badvpn/archive/1.999.130.tar.gz
tar xvzf 1.999.130.tar.gz
cd badvpn-1.999.130
cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1 -DBUILD_UDPGW=1
make install
make -i install

cd
# auto start badvpn single port
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10' /etc/rc.local
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 20 &

# permition
chmod +x /usr/local/bin/badvpn-udpgw
chmod +x /usr/local/share/man/man7/badvpn.7
chmod +x /usr/local/bin/badvpn-tun2socks
chmod +x /usr/local/share/man/man8/badvpn-tun2socks.8
chmod +x /usr/bin/build
chmod +x /etc/rc.local

# Custom Banner SSH

echo "================  Banner ======================"
wget -O /etc/issue.net "https://github.com/idtunnel/sshtunnel/raw/master/debian9/banner-custom.conf"
chmod +x /etc/issue.net

echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
echo "DROPBEAR_BANNER="/etc/issue.net"" >> /etc/default/dropbear


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


cd
# iptables-persistent
echo "================  Firewall ======================"
apt install iptables-persistent -y
wget https://raw.githubusercontent.com/4hidessh/sshtunnel/master/firewall-torent
chmod +x firewall-torent
bash firewall-torent
netfilter-persistent save
netfilter-persistent reload 


# download script

echo "================  install Menu tambahan ======================"
cd /usr/bin
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


# autoreboot 12 jam

echo "================  Auto Reboot ======================"
echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

#finishing
chown -R www-data:www-data /home/vps/public_html

# info
clear
echo "Autoscript Include:" | tee log-install.txt
echo "===========================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Service"  | tee -a log-install.txt
echo "-------"  | tee -a log-install.txt
echo "OpenSSH   : 22,"  | tee -a log-install.txt
echo "Dropbear  : 44,77"  | tee -a log-install.txt
echo "SSL       : 222,443"  | tee -a log-install.txt
echo "Squid3    : 8080,3128 (limit to IP SSH)"  | tee -a log-install.txt
echo "badvpn    : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "===========================================" | tee -a log-install.txt
echo "menu      : Menampilkan daftar perintah yang tersedia"  | tee -a log-install.txt
echo "usernew   : Membuat Akun SSH"  | tee -a log-install.txt
echo "trial     : Membuat Akun Trial"  | tee -a log-install.txt
echo "hapus     : Menghapus Akun SSH"  | tee -a log-install.txt
echo "cek       : Cek User Login"  | tee -a log-install.txt
echo "member    : Cek Member SSH"  | tee -a log-install.txt
echo "jurus69   : Restart Service dropbear, squid3, stunnel4, vpn, ssh)"  | tee -a log-install.txt
echo "reboot    : Reboot VPS"  | tee -a log-install.txt
echo "speedtest : Speedtest VPS"  | tee -a log-install.txt
echo "info      : Menampilkan Informasi Sistem"  | tee -a log-install.txt
echo "delete    : auto Delete user expired"  | tee -a log-install.txt
echo "about     : Informasi tentang script auto install"  | tee -a log-install.txt


#hapus auto installer l2tp/SSH
rm -rf ssh.sh
