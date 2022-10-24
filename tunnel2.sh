#!/bin/sh
#script auto installer SSH + Wireguard
#created bye HideSSH.com and Kumpulanremaja.com
#belajar
#OS Debian 9
apt-get update && apt-get upgrade -y
apt-get install wget curl -y
#installer auto SSH, Dropbear , Stunnel, badVPN
cd
wget https://raw.githubusercontent.com/4hidessh/sshtunnel/master/debian10/ssh-baru.sh && chmod +x ssh-baru.sh && ./ssh-baru.sh


#wireguard
wget https://raw.githubusercontent.com/idtunnel/sshtunnel/master/debian9/wg.sh && chmod +x wg.sh && ./wg.sh

reboot
