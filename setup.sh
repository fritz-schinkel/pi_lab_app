#!/usr/bin/env bash
# Complete Raspberry Pi Access Point Setup with JupyterLab Service

set -e

### CONFIGURATION VARIABLES ###
JUP_USER="<your username>"
AP_SSID="<your AP SSID>"
AP_WIFI_PASS="<your AP passphrase, min 8 chars>"
AP_IP="192.168.4.1"
RANGE_START="192.168.4.10"
RANGE_END="192.168.4.50"

if [ "${JUP_USER}" = '<your username>' ] || [ "${AP_SSID}" = '<your AP SSID>' ] || [ "${AP_WIFI_PASS}" = '<your AP passphrase, min 8 chars>' ]; then
	echo "Please adapt configuration variables at the beginning of the script!"
	exit 1
fi

echo "[1/10] Updating system and installing packages..."
sudo apt update && sudo apt -y upgrade
sudo apt -y install dhcpcd dnsmasq hostapd git python3-venv python3-pip python3-full

echo "[2/10] Creating JupyterLab environment..."
mkdir -p /opt/jupyterlab
python3 -m venv /opt/jupyterlab/venv
/opt/jupyterlab/venv/bin/pip install --upgrade pip
/opt/jupyterlab/venv/bin/pip install jupyterlab

echo "[3/10] Creating JupyterLab systemd service..."
sudo cat <<EOF >/etc/systemd/system/juplabd.service
[Unit]
Description=JupyterLab Server
After=network.target

[Service]
Type=simple
ExecStart=/opt/jupyterlab/venv/bin/jupyter lab --ip=0.0.0.0 --no-browser --NotebookApp.token='' --NotebookApp.password=''
WorkingDirectory=/home/${JUP_USER}
User=${JUP_USER}
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "[4/10] Creating dhcpcd configuration..."
sudo cat <<EOF >/etc/dhcpcd.conf
interface wlan0
static ip_address=${AP_IP}/24
nohook wpa_supplicant
EOF

echo "[5/10] Creating dnsmasq configuration..."
sudo cat <<EOF >/etc/dnsmasq.conf
interface=wlan0
dhcp-range=${RANGE_START},${RANGE_END},255.255.255.0,24h
dhcp-option=3   # no router
dhcp-option=6   # no DNS (local only)
EOF

echo "[6/10] Creating hostapd configuration..."
sudo cat <<EOF >/etc/hostapd/hostapd.conf
interface=wlan0
ssid=${AP_SSID}
hw_mode=g
channel=6
wmm_enabled=0
auth_algs=1
wpa=2
wpa_passphrase=${AP_WIFI_PASS}
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
driver=nl80211
EOF

sudo sed -i 's|#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

echo "7/10] Creating AP ON/OFF scripts in /usr/local/bin ..."

sudo cat <<'EOF' >/usr/local/bin/ap_on
#!/bin/bash

echo "Stopping NetworkManager ..."
sudo systemctl stop NetworkManager.service 2>/dev/null

echo "Stopping wpa_supplicant ..."
sudo systemctl stop wpa_supplicant.service

echo "Restarting dhcpcd ..."
sudo systemctl restart dhcpcd

echo "Restarting dnsmasq ..."
sudo systemctl restart dnsmasq
sleep 2

echo "Restarting hostapd ..."
sudo systemctl restart hostapd

echo "📡 Access Point aktiv → SSID: ${AP_SSID} ({AP_IP})"
sudo systemctl status --no-page hostapd
EOF
sudo chmod +x /usr/local/bin/ap_on

sudo cat <<'EOF' >/usr/local/bin/ap_off
#!/bin/bash

echo "Stopping hostapd ..."
sudo systemctl stop hostapd

echo "Stopping dnsmasq ..."
sudo systemctl stop dnsmasq

echo "Restarting dhcpcd ..."
sudo systemctl restart dhcpcd

echo "Starting wpa_supplicant ..."
sudo systemctl start wpa_supplicant.service

echo "Starting NetworkManager ..."
sudo systemctl start NetworkManager.service 2>/dev/null
echo "📶 WLAN client active → Internet accessible"
EOF
sudo chmod +x /usr/local/bin/ap_off

echo "[8/10] Creating show_ap_config..."

sudo cat <<'EOF' >/usr/local/bin/show_ap_config
#!/bin/bash
echo "====== ACCESS POINT CONFIGURATION ================================"

echo "====== dhcpcd ===================================================="
echo "/etc/dhcpcd.conf"
sudo cat /etc/dhcpcd.conf
systemctl status dhcpcd --no-pager

echo
echo "====== dnsmasq ==================================================="
echo "/etc/dnsmasq.conf"
sudo cat /etc/dnsmasq.conf
systemctl status dnsmasq --no-pager

echo
echo "====== hostapd ==================================================="
echo "/etc/hostapd/hostapd.conf"
sudo cat /etc/hostapd/hostapd.conf
systemctl status hostapd --no-pager

echo
echo "====== NetworkManager ============================================"
#echo "/etc/?.conf"
#sudo cat /etc/?.conf
systemctl status NetworkManager --no-pager

echo
echo "====== wpa_supplicant ============================================"
# echo "/etc/?.conf"
# sudo cat /etc/?.conf
systemctl status wpa_supplicant --no-pager

echo
echo "====== juplabd ==================================================="
systemctl status juplabd --no-pager
EOF
sudo chmod +x /usr/local/bin/show_ap_config


echo "[9/10] Enabling / disabling services..."
systemctl unmask dhcpcd
systemctl enable dhcpcd
systemctl unmask dnsmasq
systemctl enable dnsmasq
systemctl unmask hostapd
systemctl enable hostapd
systemctl unmask juplabd.service
systemctl enable juplabd.service
systemctl unmask NetworkManager
systemctl disable NetworkManager
systemctl unmask wpa_supplicant
systemctl disable wpa_supplicant


echo "[10/10] Setup complete. Do possible additional installations. after that reboot for start in AP mode."
echo "Run 'sudo reboot' now."
