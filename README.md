# pi_da_tut - Digital Annealer Tutorial on Raspberry PI Zero 2W

## Install OS Image

Install your Rapsberry Pi 2W with "lite" image. Therefor download Raspberry Pi Imager on your PC from https://www.raspberrypi.com/software/ and start the software. Select the model ``Raspberry Pi Zero 2W``. Under ``Raspberry PI OS (other)`` you will find 
- ``Raspberry PI OS Lite (64-bit)`` or 
- ``Raspberry PI OS (Legacy, 64-bit) Lite``. 
Both are suited, the second one ist older and more stable. Select one of those. Define the requested content for hostname, user and access to your local WLAN. If it is possible for your selected image please activate the option SSH. Finally transfer the image to a micro sd card. After completion take the SD card and mount it onto your pi.
- 
## First Power Up
Connect the pi with keyboard, monitor and power. Enter your preferred settings and user credentials. Then sign as the new user. Start the configuration menu:
 ```
 sudo raspi-config
 ```
 Set the local WLAN and activate SSH.

 If you could activate SSH during image creation, then you don't need the keyboard and monitor connected to the pi. You may skip that step and connect directly via SSH to the pi in your local WLAN.

## Setup the Software
If not available first install git on your pi:
```
sudo apt -y install git
```

Next get the base components from git. Make sure to have a good connection to your WLAN to avoid a long setup process. Clone repository ``pi_da_tut`` to your system:
```
git clone https://github.com/fritz-schinkel/pi_da_tut.git
```

This leads you to the setup script that should be executed next:
```
cd pi_da_tut
./setup.sh
```

Next we copy the tutorial to ``~/pi_da_tut`` on our machine using e.g. FileZilla. From that we can install the ``dadk``:
````
cd da-tutorial
pip install -U Software/dadk-light.tar.bz2
````

After successful installation reboot the pi.
````commandline
sudo reboot
````
sudo pip install -U 

The pi will by default come up as access point. You can connect to the ssid as defined in the setup.sh script. Then you can connect to jupyter lab:

````commandline
http://192.168.4.1:8888/lab
````

If you need further installations from the internet you can connect the pi with your local WLAN again. The commands ``ap_on`` and ``ap_off`` toggle between these modes. When you execute the commands via ssh session the connection gets lost and you have to connect a new ssh session in the other context (server in your local WLAN vs. visible access point connection and then 192.168.4.1).