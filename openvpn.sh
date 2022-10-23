#!/bin/bash
#
# Original script by fornesia, rzengineer and fawzya
# Mod by admin Hidessh
#beljar
# ==================================================


# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

#update dan upgrade 
apt update -y
apt upgrade -y

 
# install webserver
cd
apt-get -y install nginx
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/nginx-default.conf"
mkdir -p /home/vps/public_html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/vhost-nginx.conf"
/etc/init.d/nginx restart


# Install OpenVPN dan Easy-RSA
apt install openvpn
apt install openssl iptables -y 


# copykan script generate Easy-RSA ke direktori OpenVPN
cp -r /usr/share/easy-rsa/ /etc/openvpn

# Buat direktori baru untuk easy-rsa keys
mkdir /etc/openvpn/easy-rsa/keys

# Kemudian edit file variabel easy-rsa
# nano /etc/openvpn/easy-rsa/vars
wget -O /etc/openvpn/easy-rsa/vars "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/openvpn-conf.sh"

# generate Diffie hellman parameters
openssl dhparam -out /etc/openvpn/dh2048.pem 2048

# inialisasikan Public Key
cd /etc/openvpn/easy-rsa

# inialisasikan openssl.cnf
ln -s openssl-1.0.0.cnf openssl.cnf
echo "unique_subject = no" >> keys/index.txt.attr

# inialisasikan vars
. ./vars

# inialisasikan Public clean all
./clean-all

# Certificate Authority (CA)
./build-ca

# buat server key name yang telah kita buat sebelum nya yakni "white-vps"
./build-key-server hidessh

# generate ta.key
openvpn --genkey --secret keys/ta.key

# Buat config server UDP 1194
cd /etc/openvpn

cat > /etc/openvpn/server-udp-1194.conf <<-END
port 1194
proto udp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/hidessh.crt
key easy-rsa/keys/hidessh.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 10.5.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 94.140.14.15"
push "dhcp-option DNS 94.140.15.16"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-udp-1194.log
verb 3
END

# Buat config server TCP 1194
cat > /etc/openvpn/server-tcp-1194.conf <<-END
port 1194
proto tcp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/hidessh.crt
key easy-rsa/keys/hidessh.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 10.6.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 94.140.14.15"
push "dhcp-option DNS 94.140.15.16"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-tcp-1194.log
verb 3
END

# Buat config server UDP 2200
cat > /etc/openvpn/server-udp-2200.conf <<-END
port 2200
proto udp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/hidessh.crt
key easy-rsa/keys/hidessh.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 10.7.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 94.140.14.15"
push "dhcp-option DNS 94.140.15.16"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-udp-2200.log
verb 3
END

# Buat config server TCP 2200
cat > /etc/openvpn/server-tcp-2200.conf <<-END
port 2200
proto tcp
dev tun
ca easy-rsa/keys/ca.crt
cert easy-rsa/keys/whidessh.crt
key easy-rsa/keys/hidessh.key
dh dh2048.pem
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
client-cert-not-required
username-as-common-name
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 94.140.14.15"
push "dhcp-option DNS 94.140.15.16"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status server-tcp-2200.log
verb 3
END

cd

cp /etc/openvpn/easy-rsa/keys/{hidessh.crt,hidessh.key,ca.crt,ta.key} /etc/openvpn
ls /etc/openvpn

# nano /etc/default/openvpn
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn
# Cari pada baris #AUTOSTART=”all” hilangkan tanda pagar # didepannya sehingga menjadi AUTOSTART=”all”. Save dan keluar dari editor

# restart openvpn dan cek status openvpn
/etc/init.d/openvpn restart
/etc/init.d/openvpn status

# aktifkan ip4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
# edit file sysctl.conf
# nano /etc/sysctl.conf
# Uncomment hilangkan tanda pagar pada #net.ipv4.ip_forward=1

# Konfigurasi dan Setting untuk Client
mkdir clientconfig
cp /etc/openvpn/easy-rsa/keys/{hidessh.crt,hidessh.key,ca.crt,ta.key} clientconfig/
cd clientconfig

# Buat config client UDP 1194
cd /etc/openvpn
cat > /etc/openvpn/client-udp-1194.ovpn <<-END
##### WELCOME TO HideSSH #####
##### WWW.HideSSH.COM #####
##### DONT FORGET TO SUPPORT US #####
client
dev tun
proto udp
remote xxxxxxxxx 1194
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/client-udp-1194.ovpn;

# Buat config client TCP 1194
cat > /etc/openvpn/client-tcp-1194.ovpn <<-END
##### WELCOME TO HideSSH #####
##### WWW.HideSSHSSH.COM #####
##### DONT FORGET TO SUPPORT US #####
client
dev tun
proto tcp
remote xxxxxxxxx 1194
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/client-tcp-1194.ovpn;

# Buat config client UDP 2200
cat > /etc/openvpn/client-udp-2200.ovpn <<-END
##### WELCOME TO HideSSH #####
##### WWW.HideSSH.COM #####
##### DONT FORGET TO SUPPORT US #####
client
dev tun
proto udp
remote xxxxxxxxx 2200
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/client-udp-2200.ovpn;

# Buat config client TCP 2200
cat > /etc/openvpn/client-tcp-2200.ovpn <<-END
##### WELCOME TO HideSSH #####
##### WWW.HideSSH.COM #####
##### DONT FORGET TO SUPPORT US #####
client
dev tun
proto tcp
remote xxxxxxxxx 2200
##### Modification VPN #####
http-proxy-retry
http-proxy xxxxxxxxx 3128
http-proxy-option CUSTOM-HEADER Host google.com
##### DONT FORGET TO SUPPORT US #####
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

cd

sed -i $MYIP2 /etc/openvpn/client-tcp-2200.ovpn;

# pada tulisan xxx ganti dengan alamat ip address VPS anda 
/etc/init.d/openvpn restart

# masukkan certificatenya ke dalam config client TCP 1194
echo '<ca>' >> /etc/openvpn/client-tcp-1194.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-tcp-1194.ovpn
echo '</ca>' >> /etc/openvpn/client-tcp-1194.ovpn

# masukkan certificatenya ke dalam config client UDP 1194
echo '<ca>' >> /etc/openvpn/client-udp-1194.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-udp-1194.ovpn
echo '</ca>' >> /etc/openvpn/client-udp-1194.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( TCP 1194 )
cp /etc/openvpn/client-tcp-1194.ovpn /home/vps/public_html/client-tcp-1194.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( UDP 1194 )
cp /etc/openvpn/client-udp-1194.ovpn /home/vps/public_html/client-udp-1194.ovpn

# masukkan certificatenya ke dalam config client TCP 2200
echo '<ca>' >> /etc/openvpn/client-tcp-2200.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-tcp-2200.ovpn
echo '</ca>' >> /etc/openvpn/client-tcp-2200.ovpn

# masukkan certificatenya ke dalam config client UDP 2200
echo '<ca>' >> /etc/openvpn/client-udp-2200.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/client-udp-2200.ovpn
echo '</ca>' >> /etc/openvpn/client-udp-2200.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( TCP 2200 )
cp /etc/openvpn/client-tcp-2200.ovpn /home/vps/public_html/client-tcp-2200.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( UDP 2200 )
cp /etc/openvpn/client-udp-2200.ovpn /home/vps/public_html/client-udp-2200.ovpn

 # Allow IPv4 Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf


#Reset iptables
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

ifes="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)";
IPCIDR='10.5.0.0/24'
IPCIDR2='10.6.0.0/24'
IPCIDR3='10.7.0.0/24'
IPCIDR4='10.8.0.0/24'

iptables -t nat -A POSTROUTING -o $ifes -j MASQUERADE
iptables -t nat -A POSTROUTING $IPCIDR -o $ifes -j MASQUERADE
iptables -t nat -A POSTROUTING $IPCIDR2 -o $ifes -j MASQUERADE
iptables -t nat -A POSTROUTING $IPCIDR3 -o $ifes -j MASQUERADE
iptables -t nat -A POSTROUTING $IPCIDR4 -o $ifes -j MASQUERADE


#iptables save
netfilter-persistent save
netfilter-persistent reload

 
# Restart service openvpn
systemctl enable openvpn/
systemctl start openvpn
/etc/init.d/openvpn restart
