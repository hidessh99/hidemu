#!/bin/bash
#auto installer SSH + Websocket + SSHLH + badVPN
#created HideSSH
if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
fi
if [ "$(systemd-detect-virt)" == "openvz" ]; then
		echo "OpenVZ is not supported"
		exit 1
fi

red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'
MYIP=$(wget -qO- icanhazip.com);
echo "Checking VPS"
IZIN=$( curl http://ipinfo.io/ip | grep $MYIP )
if [ $MYIP = $IZIN ]; then
echo -e "${green}Permintaan Diterima...${NC}"
else
echo -e "${red}Permintaan Ditolak!${NC}";
echo "Hanya untuk pengguna terdaftar"
fi
mkdir /etc/v2ray
mkdir /var/lib/crot-script;
clear

echo "Masukkan Domain Anda, Jika Anda Tidak Memiliki Domain Klik Enter"
echo "Ketikkan Perintah addhost setelah proses instalasi Script Selesai"
read -p "Hostname / Domain: " host
echo "IP=$host" >> /var/lib/crot-script/ipvps.conf
cho "$host" >> /etc/v2ray/domain

rm -rf sshws.sh
#installh auto installer SSH
wget https://raw.githubusercontent.com/4hidessh/hidessh/main/setup/ssh1.sh && chmod +x ssh1.sh && screen -S ssh1.sh ./ssh1.sh
echo "MTungu 5 detik proses selanjutnya"
sleep 5
wget https://raw.githubusercontent.com/4hidessh/hidessh/main/setup/pythonws.sh && chmod +x pythonws.sh && screen -S pythonws.sh ./pythonws.sh


rm -rf ssh1.sh 
rm -rf pythonws.sh
