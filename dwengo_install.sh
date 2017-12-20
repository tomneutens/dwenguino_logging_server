if [ $UID -ne 0 -o -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  echo "Must run as root using 'sudo -E bash'"
  exit 1
fi

cd /root

# Update tree
apt-get update

# Update system
apt-get -f install

# Install software: Chrome, Java
apt install -y chromium-browser openjdk-9-jre

# Arduino
ARDU_VERSION=arduino-1.8.3
ARDU_ARCH=linux64
wget --continue http://downloads.arduino.cc/${ARDU_VERSION}-${ARDU_ARCH}.tar.xz
tar xf ${ARDU_VERSION}-${ARDU_ARCH}.tar.xz
rm -rf /opt/arduino
mv ${ARDU_VERSION} /opt/arduino
#   desktop icon
sudo -i -u ${SUDO_USER} bash /opt/arduino/install.sh
#   dwengo board package
sudo -i -u ${SUDO_USER} mkdir -p ~/.arduino15
echo -e 'board=Dwenguino\ntarget_package=dwenguino\ntarget_platform=avr\nboardsmanager.additional.urls=http://www.dwengo.org/sites/default/files/package_dwengo.org_dwenguino_index.json' | sudo -i -u ${SUDO_USER} tee -a ~/.arduino15/preferences.txt
sudo -i -u ${SUDO_USER} /opt/arduino/arduino --install-boards dwenguino:avr

# settings
usermod -a -G dialout ${SUDO_USER}
usermod -a -G tty ${SUDO_USER}
apt-get purge -y modemmanager*

# DwenguinoBlockly
sudo -i -u ${SUDO_USER} mkdir -p ~/Arduino/tools
wget --continue https://github.com/dwengovzw/Blockly-for-Dwenguino/raw/version2.2/bin/DwenguinoBlocklyArduinoPlugin.zip
unzip DwenguinoBlocklyArduinoPlugin.zip
rm -rf /opt/arduino/tools/DwenguinoBlocklyArduinoPlugin
mv DwenguinoBlocklyArduinoPlugin /opt/arduino/tools/

# wallpaper
wget http://ptr.be/dwengo/dwengo.jpg
mv dwengo.jpg /usr/share/xfce4/backdrops/dwengo.jpg
sudo -E -u ${SUDO_USER} xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image --set /usr/share/xfce4/backdrops/dwengo.jpg

# remove filesystem icon
#    (hint: to find the property names, run "xfconf-query -c xfce4-desktop -m" while changing settings through the GUI
sudo -E -u ${SUDO_USER} xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem --set false

# dwengo, shop links
sudo -i -u ${SUDO_USER} tee ~/Desktop/Dwengo.desktop <<EOT
[Desktop Entry]
Version=1.0
Type=Link
Name=Dwengo
Comment=
Icon=gnome-fs-bookmark
URL=http://www.dwengo.org/
EOT
sudo -i -u ${SUDO_USER} tee ~/Desktop/Dwengo\ Shop.desktop <<EOT
[Desktop Entry]
Version=1.0
Type=Link
Name=Dwengo Shop
Comment=
Icon=gnome-fs-bookmark
URL=http://shop.dwengo.org/
EOT
chmod +x /home/${SUDO_USER}/Desktop/Dwengo*.desktop

# Google Blockly
wget https://github.com/google/blockly-games/raw/offline/generated/blockly-games-nl.zip
unzip blockly-games-nl.zip
sudo -i -u ${SUDO_USER} mv /root/blockly-games /home/${SUDO_USER}/Desktop/

# Install python pip
apt install -y python3-pip
pip3 install pymongo

# Install mongodb
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
apt-get update
apt-get install -y mongodb-org
touch /etc/systemd/system/mongod.service
bash -c 'echo "[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target

[Service]
User=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/mongod.service'


mkdir -p /data/db
sudo chmod -R 755 /data/db

# Start mongo service at statup
systemctl enable mongod.service

#get the logging script
wget --continue https://raw.githubusercontent.com/tomneutens/dwenguino_logging_server/master/data_logger.py
sudo mv data_logger.py /bin/data_logger.py
sudo chmod 777 /bin/data_logger.py

sudo touch /lib/systemd/blockly_logging_startup.service

# Configure logging as service which starts at startup
sudo bash 'echo "[Unit]
Description=Blockly logger

[Service]
Type=simple
ExecStart=/bin/data_logger.py

[Install]
WantedBy=multi-user.target" > /lib/systemd/blockly_logging_startup.service'

sudo systemctl daemon-reload
sudo systemctl enable blockly_logging_startup.service
