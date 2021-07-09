#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 -o "x${SUDO_USER}" = "x" ]]; then
   echo "This script must be called from sudo under the user account you wish to setup."
   exit 1
fi

USER_HOME=$(eval echo ~${SUDO_USER})

#Install new repos and update once instead of many times.
echo "----> Adding new repos"
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

#Perform first time package refresh and update
echo "----> Updating package caches and updating system before proceeding with installs"
apt update
apt upgrade -y

#Install some basic needs
echo "----> Installing some basic tools"
apt install -y open-vm-tools-desktop vim tilix remmina gnome-tweaks code apt-transport-https curl papirus-icon-theme ca-certificates bash-completion gir1.2-gmenu-3.0 gnome-menus openconnect network-manager-openconnect network-manager-openconnect-gnome openvpn network-manager-openvpn-gnome fzf

#Install Brave and Purge out Firefox
echo "----> Installing Brave because FF sucks"
apt install -y brave-browser
echo "----> Removing firefox"
apt remove -y --purge firefox*

#Install WhiteSur Theme with GTK and login screen
#echo "----> Installing WhiteSur Theme"
#mkdir -p $USER_HOME/Development/WhiteSur-gtk-theme
#git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git $USER_HOME/Development/WhiteSur-gtk-theme
#$USER_HOME/Development/WhiteSur-gtk-theme/install.sh -N glassy 
#$USER_HOME/Development/WhiteSur-gtk-theme/tweaks.sh -g -c dark

#Install FiraCode Nerd Font
echo "----> Installing Nerd Font"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
unzip FiraCode.zip -d /usr/local/share/fonts
rm -f FiraCode.zip
fc-cache -fv

#Install Starship Prompt
echo "----> Installing starship prompt"
sh -c "$(curl -fsSL https://starship.rs/install.sh)"

#Install Kubectl, Kubectx, and Kubens(and autocompletion.)
echo "----> Installing Kubectl"
apt install -y kubectl
echo "----> Installing Kubectx and Kubens"
mkdir -p $USER_HOME/Development/kubectx
mkdir -p /opt/kubectx
git clone https://github.com/ahmetb/kubectx.git $USER_HOME/Development/kubectx
wget https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubectx_v0.9.3_linux_x86_64.tar.gz
wget https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubens_v0.9.3_linux_x86_64.tar.gz
tar -zvxf kubectx_v0.9.3_linux_x86_64.tar.gz --directory /opt/kubectx
tar -zvxf kubens_v0.9.3_linux_x86_64.tar.gz --directory /opt/kubectx
rm -f kubectx_v0.9.3_linux_x86_64.tar.gz
rm -f kubens_v0.9.3_linux_x86_64.tar.gz
ln -s /opt/kubectx/kubectx /usr/bin/kubectx
ln -s /opt/kubectx/kubens /usr/bin/kubens
echo "----> Setting up autocompletions"
kubectl completion bash >/etc/bash_completion.d/kubectl
COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
ln -sf $USER_HOME/Development/kubectx/completion/kubens.bash $COMPDIR/kubens
ln -sf $USER_HOME/Development/kubectx/completion/kubectx.bash $COMPDIR/kubectx

#Install Terraform
echo "----> Installing Terraform" 
apt install -y terraform

#Install AWS CLi
echo "----> Installing AWS CLi"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf ./aws ./awscliv2.zip

#Set Tilix to default terminal
echo "----> Setting default terminal to Tilix"
update-alternatives --set x-terminal-emulator /usr/bin/tilix.wrapper

echo "I'm done, you need to untar your home directory backup and your .bashrc backup. Also use the tweaks tool to set the whitesur theme and the papirus icons if you so choose."
exit 0
