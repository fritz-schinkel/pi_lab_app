#!/usr/bin/env bash
# Raspberry Pi Access Point Setup with JupyterLab Service

set -e

### CONFIGURATION VARIABLES ###
JUP_USER="$(whoami)"
AP_SSID="LabApp"
AP_WIFI_PASS="your_AP_passphrase_min_8_chars"
AP_IP="192.168.42.41"
RANGE_START="192.168.4.1"
RANGE_END="192.168.4.40"

if [ "${JUP_USER}" = "$(whoami)" ] || [ "${AP_SSID}" = "LabApp" ] || [ "${AP_WIFI_PASS}" = "your_AP_passphrase_min_8_chars" ]; then
  read -p "Do you want to adapt configuration variables at the beginning of the script? (y/n) " choice

  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Please adapt configuration variables at the beginning of the script!"
    exit 1
  else
    echo "Continuing with default values for all variables."
  fi
fi

echo "[1/10] Updating system and installing packages..."
sudo apt update && sudo apt -y upgrade
sudo apt -y install dhcpcd dnsmasq hostapd git python3-venv python3-pip python3-full

echo "[2/10] Creating JupyterLab environment..."
sudo mkdir -p /opt/jupyterlab
sudo chown "${JUP_USER}" /opt/jupyterlab
python3 -m venv /opt/jupyterlab/venv
/opt/jupyterlab/venv/bin/pip install --upgrade pip
/opt/jupyterlab/venv/bin/pip install jupyterlab

echo "[3/10] Creating JupyterLab systemd service..."

# --- Add sudo shutdown rule if not exists ---
SUDOERS_FILE="/etc/sudoers.d/jupyter_shutdown"

# Allow all sudo users to shutdown without password
RULE="%sudo ALL=(ALL) NOPASSWD: /usr/sbin/shutdown"

# Create only if not present
if [ ! -f "$SUDOERS_FILE" ] || ! grep -q "/usr/sbin/shutdown" "$SUDOERS_FILE"; then
    echo "$RULE" | sudo tee "$SUDOERS_FILE" >/dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    echo "[INFO] Added shutdown sudo rule for group sudo"
else
    echo "[INFO] Shutdown sudo rule already present"
fi

sudo bash -c "cat > /etc/systemd/system/juplabd.service <<EOF 
[Unit]
Description=JupyterLab Server
After=network.target

[Service]
Type=simple
ExecStart=/opt/jupyterlab/venv/bin/jupyter lab --ip=0.0.0.0 --no-browser --NotebookApp.token='' --NotebookApp.password=''
WorkingDirectory=/home/${JUP_USER}
User=${JUP_USER}
Restart=no
ExecStopPost=/usr/bin/sudo /usr/sbin/shutdown -h now

[Install]
WantedBy=multi-user.target
EOF"

echo "[4/10] Creating dhcpcd configuration..."
sudo bash -c "cat > /etc/dhcpcd.conf <<EOF
interface wlan0
static ip_address=${AP_IP}/24
nohook wpa_supplicant
EOF"

echo "[5/10] Creating dnsmasq configuration..."
sudo bash -c "cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=${RANGE_START},${RANGE_END},255.255.255.0,24h
dhcp-option=3   # no router
dhcp-option=6   # no DNS (local only)
EOF"

echo "[6/10] Creating hostapd configuration..."
sudo bash -c "cat > /etc/hostapd/hostapd.conf <<EOF
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
EOF"

sudo sed -i 's|#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

echo "7/10] Creating AP ON/OFF scripts in /usr/local/bin ..."

sudo bash -c "cat > /usr/local/bin/ap_on <<EOF
#!/bin/bash

echo 'Stopping NetworkManager ...'
sudo systemctl stop NetworkManager.service 2>/dev/null

echo 'Stopping wpa_supplicant ...'
sudo systemctl stop wpa_supplicant.service

echo 'Restarting dhcpcd ...'
sudo systemctl restart dhcpcd

echo 'Restarting dnsmasq ...'
sudo systemctl restart dnsmasq
sleep 2

echo 'Restarting hostapd ...'
sudo systemctl restart hostapd

echo '📡 Access Point aktiv → SSID: ${AP_SSID} ({AP_IP})'
sudo systemctl status --no-page hostapd
EOF"
sudo chmod +x /usr/local/bin/ap_on

sudo bash -c "cat > /usr/local/bin/ap_off <<EOF
#!/bin/bash

echo 'Stopping hostapd ...'
sudo systemctl stop hostapd

echo 'Stopping dnsmasq ...'
sudo systemctl stop dnsmasq

echo 'Restarting dhcpcd ...'
sudo systemctl restart dhcpcd

echo 'Starting wpa_supplicant ...'
sudo systemctl start wpa_supplicant.service

echo 'Starting NetworkManager ...'
sudo systemctl start NetworkManager.service 2>/dev/null
echo '📶 WLAN client active → Internet accessible'
EOF"
sudo chmod +x /usr/local/bin/ap_off

echo "[8/10] Creating show_ap_config..."

sudo bash -c "cat > /usr/local/bin/show_ap_config <<EOF
#!/bin/bash
echo '====== ACCESS POINT CONFIGURATION ================================'

echo '====== dhcpcd ===================================================='
echo '/etc/dhcpcd.conf'
sudo cat /etc/dhcpcd.conf
systemctl status dhcpcd --no-pager

echo
echo '====== dnsmasq ==================================================='
echo '/etc/dnsmasq.conf'
sudo cat /etc/dnsmasq.conf
systemctl status dnsmasq --no-pager

echo
echo '====== hostapd ==================================================='
echo '/etc/hostapd/hostapd.conf'
sudo cat /etc/hostapd/hostapd.conf
systemctl status hostapd --no-pager

echo
echo '====== NetworkManager ============================================'
#echo '/etc/?.conf'
#sudo cat /etc/?.conf
systemctl status NetworkManager --no-pager

echo
echo '====== wpa_supplicant ============================================'
# echo '/etc/?.conf'
# sudo cat /etc/?.conf
systemctl status wpa_supplicant --no-pager

echo
echo '====== juplabd ==================================================='
systemctl status juplabd --no-pager
EOF"
sudo chmod +x /usr/local/bin/show_ap_config


echo "[9/10] Enabling / disabling services..."
sudo systemctl unmask dhcpcd
sudo systemctl enable dhcpcd
sudo systemctl unmask dnsmasq
sudo systemctl enable dnsmasq
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl unmask juplabd.service
sudo systemctl enable juplabd.service
sudo systemctl unmask NetworkManager
sudo systemctl disable NetworkManager
sudo systemctl unmask wpa_supplicant
sudo systemctl disable wpa_supplicant


echo "[10/10] Setup complete. Do possible additional installations. after that reboot for start in AP mode."
echo "Run 'sudo reboot' now."
