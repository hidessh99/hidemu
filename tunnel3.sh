#!/bin/sh
#script auto installer lt2p  + Wireguard
#created bye HideSSH.com and Kumpulanremaja.com
#OS Debian 9
apt-get update && apt-get upgrade -y
apt-get install wget curl -y


wget https://git.io/vpnsetup -O vpnsetup.sh && sudo sh vpnsetup.sh

wget -O /usr/local/bin/stdev-l2tp-get-psk "https://gist.githubusercontent.com/satriaajiputra/0ddfe41a9218afb36f09d657cdfe8d91/raw/stdev-l2tp-get-psk"
wget -O /usr/local/bin/stdev-l2tp-add-user "https://gist.githubusercontent.com/satriaajiputra/0ddfe41a9218afb36f09d657cdfe8d91/raw/stdev-l2tp-add-user"
wget -O /usr/local/bin/stdev-l2tp-remove-user "https://gist.githubusercontent.com/satriaajiputra/0ddfe41a9218afb36f09d657cdfe8d91/raw/stdev-l2tp-remove-user"

chmod +x /usr/local/bin/stdev-l2tp-get-psk 
chmod +x /usr/local/bin/stdev-l2tp-add-user 
chmod +x /usr/local/bin/stdev-l2tp-remove-user 


wget https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/wg.sh && chmod +x wg.sh && ./wg.sh
