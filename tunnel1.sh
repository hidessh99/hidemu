#!/bin/sh
#script auto installer SSH + VPN LT2P/IPSec PSK
#created bye HideSSH.com and Kumpulanremaja.com
#OS Debian 9
apt-get update && apt-get upgrade -y
apt-get install wget curl -y


#auto installer L2TP/Ipsec PSk 

wget https://git.io/vpnsetup -O vpnsetup.sh && sudo sh vpnsetup.sh


#tambahan konfigurasi
wget -O /usr/local/bin/stdev-l2tp-get-psk "https://gist.githubusercontent.com/satriaajiputra/0ddfe41a9218afb36f09d657cdfe8d91/raw/stdev-l2tp-get-psk"
wget -O /usr/local/bin/stdev-l2tp-add-user "https://gist.githubusercontent.com/satriaajiputra/0ddfe41a9218afb36f09d657cdfe8d91/raw/stdev-l2tp-add-user"
wget -O /usr/local/bin/stdev-l2tp-remove-user "https://gist.githubusercontent.com/satriaajiputra/0ddfe41a9218afb36f09d657cdfe8d91/raw/stdev-l2tp-remove-user"

#permission
chmod +x /usr/local/bin/stdev-l2tp-get-psk 
chmod +x /usr/local/bin/stdev-l2tp-add-user 
chmod +x /usr/local/bin/stdev-l2tp-remove-user 

#edit SHARED IpSEC
wget -O /etc/ipsec.secrets "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/ipsec.secrets"

#installer auto SSH, Dropbear , Stunnel, badVPN
cd
wget https://raw.githubusercontent.com/4hidessh/sshtunnel/master/debian10/ssh-baru.sh && chmod +x ssh-baru.sh && ./ssh-baru.sh


cd
#add dns adguard
apt-get install resolvconf -y
wget -O /etc/resolvconf/resolv.conf.d/head "https://raw.githubusercontent.com/4hidessh/sshtunnel/master/dns" && chmod +x /etc/resolvconf/resolv.conf.d/head


cd
# iptables-persistent
echo "================  Firewall ======================"
apt install iptables-persistent -y
wget https://raw.githubusercontent.com/4hidessh/sshtunnel/master/firewall-torent && chmod +x firewall-torent && ./firewall-torent
netfilter-persistent save
netfilter-persistent reload 

#hapus script
rm -rf tunnel1.sh
rm -rf vpnsetup.sh
