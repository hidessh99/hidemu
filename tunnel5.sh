#!/bin/sh
#script auto installer SSH SSLH+ VPN LT2P/IPSec PSK
#created bye HideSSH.com and Kumpulanremaja.com
#beajar
#OS Debian 9
apt-get update && apt-get upgrade -y
apt-get install wget curl -y


#auto installer L2TP/Ipsec PSk 

wget https://git.io/vpnsetup -O vpnsetup.sh && sudo sh vpnsetup.sh

#izin

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
wget https://raw.githubusercontent.com/4hidessh/sshtunnel/master/debian10/ssh1.sh
chmod +x ssh1.sh
./ssh1.sh


#hapus script
rm -rf tunnel5.sh
rm -rf vpnsetup.sh
rm -rf ssh1.sh
