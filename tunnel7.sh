#!/bin/bash
#
# Original script by fornesia, rzengineer and fawzya 
# Mod by Janda Baper
# 
# ==================================================

# initializing var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

# company name details
country=ID
state=Semarang
locality=JawaTengah
organization=hidessh
organizationalunit=HideSSH
commonname=hidessh.com
email=admin@hidessh.com


# configure rc.local
cat <<EOF >/etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
EOF
chmod +x /etc/rc.local
systemctl daemon-reload
systemctl start rc-local

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# add dns server ipv4
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf
sed -i '$ i\echo "nameserver 1.1.1.1" > /etc/resolv.conf' /etc/rc.local
sed -i '$ i\echo "nameserver 1.0.0.1" >> /etc/resolv.conf' /etc/rc.local

# install wget and curl
apt-get -y install wget curl

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

# update
apt-get update

# install webserver
apt-get -y install nginx

# install essential package
apt-get -y install nano iptables-persistent dnsutils screen whois ngrep unzip unrar


# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/acillsadank/install/master/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Setup by JandaBaper</pre>" > /home/vps/public_html/index.html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/acillsadank/install/master/vps.conf"

# install openvpn
apt-get -y install openvpn easy-rsa openssl
cp -r /usr/share/easy-rsa/ /etc/openvpn
mkdir /etc/openvpn/easy-rsa/keys
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="ID"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="JAWATENGAH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="SEMARANG"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_ORG="Fort-Funston"|export KEY_ORG="HIDESSH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL="admin@hidessh.com"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU="MyOrganizationalUnit"|export KEY_OU="HideSSH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_NAME="EasyRSA"|export KEY_NAME="HideSSH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU=changeme|export KEY_OU="HideSSH"|' /etc/openvpn/easy-rsa/vars

# Create Diffie-Helman Pem
openssl dhparam -out /etc/openvpn/dh2048.pem 2048

# Create PKI
cd /etc/openvpn/easy-rsa
cp openssl-1.0.0.cnf openssl.cnf
. ./vars
./clean-all
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $*

# Create key server
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server

# Setting KEY CN
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" client

# cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn
cd
cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn/server.crt
cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn/server.key
cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/ca.crt
chmod +x /etc/openvpn/ca.crt

# server settings
cd /etc/openvpn/
wget -O /etc/openvpn/server-tcp-1194.conf"https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/server-tcp-1194.conf"
wget -O /etc/openvpn/server-udp-1194.conf "https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/server-udp-1194.conf"

systemctl start openvpn@server
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
ifes="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)";
iptables -t nat -I POSTROUTING -o $ifes -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o $ifes -j MASQUERADE
iptables -t nat -I POSTROUTING -s 192.168.200.0/24 -o $ifes -j MASQUERADE
iptables-save > /etc/iptables.up.rules
wget -O /etc/network/if-up.d/iptables "https://raw.githubusercontent.com/acillsadank/install/master/iptables"
chmod +x /etc/network/if-up.d/iptables
sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn@.service
systemctl daemon-reload
/etc/init.d/openvpn restart

# openvpn config
wget -O /etc/openvpn/client-tcp-1194.conf"https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/client-tcp-1194.conf"
sed -i $MYIP2 /etc/openvpn/client-tcp-1194.conf;
echo '<ca>' >> /etc/openvpn/client-tcp-1194.conf
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-tcp-1194.conf
echo '</ca>' >> /etc/openvpn/client-tcp-1194.conf

cp client-tcp-1194.conf /home/vps/public_html/


wget -O /etc/openvpn/client-udp-1194.conf"https://raw.githubusercontent.com/4hidessh/hidessh/main/OVPN/client-udp-1194.conf"
sed -i $MYIP2 /etc/openvpn/client-udp-1194.conf;
echo '<ca>' >> /etc/openvpn/client-udp-1194.conf
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-udp-1194.conf
echo '</ca>' >> /etc/openvpn/client-udp-1194.conf

cp client-tcp-1194.conf /home/vps/public_html/


wget -O /etc/openvpn/openvpnssl.ovpn "https://raw.githubusercontent.com/acillsadank/install/master/openvpnssl.conf"
echo '<ca>' >> /etc/openvpn/openvpnssl.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/openvpnssl.ovpn
echo '</ca>' >> /etc/openvpn/openvpnssl.ovpn

cp openvpnssl.ovpn /home/vps/public_html/

# install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/acillsadank/install/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/acillsadank/install/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200

# setting port ssh
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config

# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 443 -p 990"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/dropbear restart

# install squid
apt-get -y install squid
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/acillsadank/install/master/squid3.conf"
sed -i $MYIP2 /etc/squid/squid.conf;

# install stunnel
apt-get install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 444
connect = 127.0.0.1:143

[openvpn]
accept = 442
connect = 127.0.0.1:1194

END

# make a certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# configure stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
cd /etc/stunnel/
wget -O /etc/stunnel/ssl.conf "https://raw.githubusercontent.com/acillsadank/install/master/ssl.conf"
sed -i $MYIP2 /etc/stunnel/ssl.conf;
cp ssl.conf /home/vps/public_html/
cd

# colored text
apt-get -y install ruby
gem install lolcat

# install fail2ban
apt-get -y install fail2ban

# install ddos deflate
cd
apt-get -y install dnsutils dsniff
wget https://raw.githubusercontent.com/janda09/install/master/ddos-deflate-master.zip
unzip ddos-deflate-master.zip
cd ddos-deflate-master
./install.sh
rm -rf /root/ddos-deflate-master.zip

# common password debian 
wget -O /etc/pam.d/common-password "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/common-password-deb9"
chmod +x /etc/pam.d/common-password


# Custom Banner SSH

echo "================  Banner ======================"
wget -O /etc/issue.net "https://github.com/idtunnel/sshtunnel/raw/master/debian9/banner-custom.conf"
chmod +x /etc/issue.net

echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
echo "DROPBEAR_BANNER="/etc/issue.net"" >> /etc/default/dropbear



# download script
cd /usr/bin
wget -O menu "https://raw.githubusercontent.com/acillsadank/install/master/menu.sh"
wget -O edit "https://raw.githubusercontent.com/acillsadak/install/master/edit-ports.sh"
wget -O edit-dropbear "https://raw.githubusercontent.com/acillsadak/install/master/edit-dropbear.sh"
wget -O edit-openssh "https://raw.githubusercontent.com/acillsadak/install/master/edit-openssh.sh"
wget -O edit-openvpn "https://raw.githubusercontent.com/acillsadak/install/master/edit-openvpn.sh"
wget -O edit-squid3 "https://raw.githubusercontent.com/acillsadak/install/master/edit-squid3.sh"
wget -O edit-stunnel4 "https://raw.githubusercontent.com/acillsadak/install/master/edit-stunnel4.sh"
wget -O show-ports "https://raw.githubusercontent.com/acillsadak/install/master/show-ports.sh"
wget -O usernew "https://raw.githubusercontent.com/acillsadak/install/master/usernew.sh"
wget -O trial "https://raw.githubusercontent.com/acillsadak/install/master/trial.sh"
wget -O delete "https://raw.githubusercontent.com/acillsadak/install/master/delete.sh"
wget -O check "https://raw.githubusercontent.com/acillsadak/install/master/user-login.sh"
wget -O member "https://raw.githubusercontent.com/acillsadak/install/master/user-list.sh"
wget -O restart "https://raw.githubusercontent.com/acillsadak/install/master/restart.sh"
wget -O speedtest "https://raw.githubusercontent.com/acillsadak/install/master/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/acillsadak/install/master/info.sh"
wget -O about "https://raw.githubusercontent.com/acillsadak/install/master/about.sh"

chmod +x menu
chmod +x edit
chmod +x edit-dropbear
chmod +x edit-openssh
chmod +x edit-openvpn
chmod +x edit-squid3
chmod +x edit-stunnel4
chmod +x show-ports
chmod +x usernew
chmod +x trial
chmod +x delete
chmod +x check
chmod +x member
chmod +x restart
chmod +x speedtest
chmod +x info
chmod +x about

# finishing
cd
chown -R www-data:www-data /home/vps/public_html
/etc/init.d/nginx restart
/etc/init.d/openvpn restart
/etc/init.d/cron restart
/etc/init.d/ssh restart
/etc/init.d/dropbear restart
/etc/init.d/fail2ban restart
/etc/init.d/webmin restart
/etc/init.d/stunnel4 restart
/etc/init.d/squid start
rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# grep ports 
opensshport="$(netstat -ntlp | grep -i ssh | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
dropbearport="$(netstat -nlpt | grep -i dropbear | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
stunnel4port="$(netstat -nlpt | grep -i stunnel | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
openvpnport="$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
squidport="$(cat /etc/squid/squid.conf | grep -i http_port | awk '{print $2}')"
nginxport="$(netstat -nlpt | grep -i nginx| grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"


# remove unnecessary files
apt -y autoremove
apt -y autoclean
apt -y clean

# info
clear
echo "Autoscript Include:" | tee log-install.txt
echo "===========================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Service"  | tee -a log-install.txt
echo "-------"  | tee -a log-install.txt
echo "OpenSSH  : 22"  | tee -a log-install.txt
echo "Dropbear : 143, 443, 990"  | tee -a log-install.txt
echo "SSL      : 444" | tee -a log-install.txt
echo "OpenVPNSSL : 442"  | tee -a log-install.txt
echo "Squid3   : 80, 8080 (limit to IP SSH)"  | tee -a log-install.txt
echo "SSL      : http://$MYIP:81/ssl.conf"  | tee -a log-install.txt
echo "OpenVPNSSL: http://$MYIP:81/openvpnssl.ovpn"  | tee -a log-install.txt
echo "OpenVPN  : TCP 1194 (client config : http://$MYIP:81/client.ovpn)"  | tee -a log-install.txt
echo "badvpn   : badvpn-udpgw port 7200"  | tee -a log-install.txt
echo "nginx    : 81"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Script"  | tee -a log-install.txt
echo "------"  | tee -a log-install.txt
echo "menu (Displays a list of available commands)"  | tee -a log-install.txt
echo "edit (Edit Ports)"  | tee -a log-install.txt
echo "usernew (Creating an SSH Account)"  | tee -a log-install.txt
echo "trial (Create a Trial Account)"  | tee -a log-install.txt
echo "delete (Clearing SSH Account)"  | tee -a log-install.txt
echo "check (Check User Login)"  | tee -a log-install.txt
echo "member (Check Member SSH)"  | tee -a log-install.txt
echo "restart (Restart Service dropbear, webmin, squid3, openvpn and ssh)"  | tee -a log-install.txt
echo "reboot (Reboot VPS)"  | tee -a log-install.txt
echo "speedtest (Speedtest VPS)"  | tee -a log-install.txt
echo "info (System Information)"  | tee -a log-install.txt
echo "about (Information about auto install script)"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Other features"  | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt
echo "Webmin   : http://$MYIP:10000/"  | tee -a log-install.txt
echo "Timezone : Asia/Jakarta (GMT +7)"  | tee -a log-install.txt
echo "IPv6     : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Original Script by Fornesia, Rzengineer & Fawzya"  | tee -a log-install.txt
echo "Modified by Rizwan Arif Firmansyah"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Installation Log --> /root/log-install.txt"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "==========================================="  | tee -a log-install.txt
cd

