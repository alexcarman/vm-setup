#!/bin/bash
set -euo pipefail

#Install Gnome Extensions
echo "----> Installing Gnome Extensions"
wget -O gnome-shell-extension-installer "https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer"
chmod +x gnome-shell-extension-installer
for i in 3628 19 779 1112
do
	echo "Installing Extension $i"
	./gnome-shell-extension-installer $i
done
exit 0
