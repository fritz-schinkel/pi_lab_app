# Jupyter Lab Appliance on Raspberry PI Zero 2W

## Install OS Image

Install your Rapsberry Pi 2W with a "lite" image, desktop GUI is not recommended. Therefor download Raspberry Pi Imager on your PC from https://www.raspberrypi.com/software/ and start the software. Select the model ``Raspberry Pi Zero 2W``. Under ``Raspberry PI OS (other)`` you will find 
- ``Raspberry PI OS Lite (64-bit)`` or 
- ``Raspberry PI OS (Legacy, 64-bit) Lite``.

Both are suited, the second one ist older and more stable. Select one of those. Define the requested content for host name, user and access to your local WLAN. If it is possible for your selected image please activate the option SSH. Finally transfer the image to a micro sd card. After completion take the SD card and mount it onto your pi.

## First Power Up
 If you could activate SSH during image creation, then you don't need a keyboard or monitor connected to your pi. You can power up your pi and connect directly via SSH to your defined user on the pi in your local WLAN. You can skip the rest of this section.

Otherwise connect the pi with keyboard, monitor and power. Enter your preferred settings and user credentials. Then sign in as the new user. Start the configuration menu:
 ````commandline
 sudo raspi-config
 ````
 Set the local WLAN and activate SSH. You can now complete the setup from this console or you can connect via SSH to your defined user on the pi in your local WLAN. The latter is convenient for copying the directives from this README instead of typing.

## Setup the Software
If not available first install git on your pi:
````commandline
sudo apt -y install git
````

Next get the base components from git. Make sure to have a good connection to your WLAN to avoid a long setup process. Clone repository ``pi_lab_app`` to your system:

````commandline
git clone https://github.com/fritz-schinkel/pi_lab_app.git
````

This leads you to the setup script that should be executed next. At the beginning of the script there are variables for credentials and address ranges. At least the passphrase for the access point should be adapted before executing the script. Execute the script under your authority and NOT as superuser with sudo.

````commandline
cd pi_lab_app
./setup.sh
````

The setup configures the network services ``NetworkManager``, ``wpa_supplicant``, ``dhcpcd``, ``dnsmasq`` and ``hostapd`` to run your pi appliance either in your local WLAN network or provide an access point for clients of the Jupyter Lab appliance. Two commands ``ap_on`` and ``ap_off`` are provided to switch between the two modi if necessary. Jupyter Lab is installed in a dedicated virtual environment.

After completion of the setup script you can copy additional data onto the appliance or install additional software. For copying ``scp`` or more convenient tools like e.g. FileZilla can be used. For installation of Python software you should first activate the virtual environment:
````commandline
source /opt/jupyterlab/venv/bin/activate
````

After successful installation reboot the pi.
````commandline
sudo reboot
````

## Usage of the Appliance
The pi by default will come up as access point. You can connect to the ssid as defined in the setup.sh script. Then you can connect to jupyter lab:

````commandline
http://192.168.42.41:8888/lab
````

If you need further installations from the internet you can connect the pi with your local WLAN again. The commands ``ap_on`` and ``ap_off`` toggle between these modes. When you execute the commands via ssh session the connection gets lost and you have to connect a new ssh session in the other context (server in your local WLAN vs. visible access point connection and then 192.168.42.41 or whatever you defined).

## Shutdown
Jupyter Lab provides the possibility to shut down the software. This will shut down the appliance as well. For restarting disconnect and reconnect the power supply. After some seconds you will se the acess point in your clients and can connect again. 
