#! /bin/bash

DISK_SIZE=4096
DISK_IMAGE=/piusb.bin
INSTALL_DIR=/opt/bagofholding
MOUNT_DIR=/mnt/usb_share
BOH_USER=boh

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
	echo "Sorry, this install script requires elevated permissions to run."
	echo "Try re-running 'sudo install.sh', or as the root user."
	exit
fi

echo "Installing pre-requisites"
apt-get install -q -o=Dpkg::Use-Pty=0 sqlite3 libsqlite3-dev jq

echo "Enabling OTG"
if ! grep -q "^dtoverlay=dwc2$" /boot/config.txt; then
	echo "dtoverlay=dwc2" >> /boot/config.txt
fi
if ! grep -q "^dwc2$" /etc/modules; then
	echo "dwc2" >> /etc/modules
fi

echo "Allocating Mass Storage disk image container"
if [[ ! -f "$DISK_IMAGE" ]]; then
	dd bs=1M if=/dev/zero of=$DISK_IMAGE count=$DISK_SIZE status=progress
	mkdosfs "$DISK_IMAGE" -F 32 -I
fi

echo "Setting up mount point"
mkdir -p "$MOUNT_DIR"
if ! grep -q "$MOUNT_DIR" /etc/fstab; then
	echo "\"$DISK_IMAGE\" $MOUNT_DIR vfat users,umask=000 0 2" >> /etc/fstab
fi

echo "Creating Bag of Holding user"
if ! getent passwd $BOH_USER > /dev/null 2>&1; then
	useradd -s /bin/false "$BOH_USER"
fi

echo "Copying conf file to /etc/boh"
if [[ ! -f "/etc/boh/boh.json" ]]; then
	mkdir -p /etc/boh
	cp ../conf/boh.json /etc/boh/json
fi

# --------------------------------

if [[ -f "$INSTALL_DIR/boh.db" ]]; then
	echo "Existing database file for Bag Of Holding found at $INSTALL_DIR/boh.db, implying this install script has already run; exiting."
	exit 
fi

echo "Setting up app in $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/conf"

sqlite3 "$INSTALL_DIR/boh.db" < boh.sql

#WIP
cp ../conf/boh.json "$INSTALL_DIR"/conf
cp ../src/remount.sh "$INSTALL_DIR"/

chown -R "$BOH_USER":"$BOH_USER" "$INSTALL_DIR"

read -n 1 -s -r -p "Done. Press any key to reboot."
reboot now
