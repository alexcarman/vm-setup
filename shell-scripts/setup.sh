#!/bin/bash
set -euo pipefail

if [ $EUID -ne 0 ] || [ "x${SUDO_USER}" = "x" ]; then
   echo "This script must be called from sudo under the user account you wish to setup."
   exit 1
fi

USER_HOME=$(eval echo ~${SUDO_USER})

#Install new repos and update once instead of many times.
echo "----> Adding new repos"
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg &> /dev/null
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list  
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg &> /dev/null
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - &> /dev/null
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" &> /dev/null

#Perform first time package refresh and update
echo "----> Updating package caches and updating system before proceeding with installs"
apt update &> /dev/null
apt upgrade -y &> /dev/null

#Install some basic needs
echo "----> Installing some basic tools"
apt install -y open-vm-tools-desktop vim tilix remmina gnome-tweaks code apt-transport-https curl ca-certificates bash-completion gir1.2-gmenu-3.0 gnome-menus openconnect network-manager-openconnect network-manager-openconnect-gnome openvpn network-manager-openvpn-gnome fzf sassc gtk2-engines-murrine graphicsmagick-imagemagick-compat jq httpie timeshift &> /dev/null

#Install Brave and Purge out Firefox
echo "----> Installing Brave because FF sucks"
apt install -y brave-browser &> /dev/null
echo "----> Removing firefox"
apt remove -y --purge firefox* &> /dev/null

#Install Orchis Theme
echo "----> Installing Orchis Theme"
mkdir -p $USER_HOME/Development/Orchis-theme
git clone https://github.com/vinceliuice/Orchis-theme.git $USER_HOME/Development/Orchis-theme &> /dev/null
$USER_HOME/Development/Orchis-theme/install.sh &> /dev/null

#Install Tela Circle Icon Theme
echo "----> Installing Tela Circle Icon Theme"
mkdir -p $USER_HOME/Development/Tela-circle-icon-theme
git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git $USER_HOME/Development/Tela-circle-icon-theme &> /dev/null
$USER_HOME/Development/Tela-circle-icon-theme/install.sh &> /dev/null

#Install FiraCode Nerd Font
echo "----> Installing Nerd Font"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip &> /dev/null
unzip FiraCode.zip -d /usr/local/share/fonts &> /dev/null
rm -f FiraCode.zip
fc-cache -fv &> /dev/null

#Install Starship Prompt
echo "----> Installing starship prompt"
curl -fsSL https://starship.rs/install.sh | bash -s -- -y &> /dev/null
echo "----> Installing the default TOML config for Starship"
cp ../resource/starship.toml $USER_HOME/.config

#Install Kubectl, Kubectx, and Kubens(and autocompletion.)
echo "----> Installing Kubectl"
apt install -y kubectl &> /dev/null
echo "----> Installing Kubectx and Kubens"
mkdir -p $USER_HOME/Development/kubectx
mkdir -p /opt/kubectx
git clone https://github.com/ahmetb/kubectx.git $USER_HOME/Development/kubectx &> /dev/null
wget https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubectx_v0.9.3_linux_x86_64.tar.gz &> /dev/null
wget https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubens_v0.9.3_linux_x86_64.tar.gz &> /dev/null
tar -zvxf kubectx_v0.9.3_linux_x86_64.tar.gz --directory /opt/kubectx &> /dev/null
tar -zvxf kubens_v0.9.3_linux_x86_64.tar.gz --directory /opt/kubectx &> /dev/null
rm -f kubectx_v0.9.3_linux_x86_64.tar.gz
rm -f kubens_v0.9.3_linux_x86_64.tar.gz
ln -s /opt/kubectx/kubectx /usr/bin/kubectx
ln -s /opt/kubectx/kubens /usr/bin/kubens
echo "----> Setting up autocompletions"
kubectl completion bash >/etc/bash_completion.d/kubectl
COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
ln -sf $USER_HOME/Development/kubectx/completion/kubens.bash $COMPDIR/kubens
ln -sf $USER_HOME/Development/kubectx/completion/kubectx.bash $COMPDIR/kubectx

#Install Kubeval
echo "----> Installing Kubeval"
wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz &> /dev/null
tar xf kubeval-linux-amd64.tar.gz &> /dev/null
cp kubeval /usr/local/bin
rm -rf kubeval*

#Install Terraform
echo "----> Installing Terraform" 
apt install -y terraform &> /dev/null

#Install AWS CLi
echo "----> Installing AWS CLi"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &> /dev/null
unzip awscliv2.zip &> /dev/null
./aws/install &> /dev/null
rm -rf ./aws ./awscliv2.zip

#Set Tilix to default terminal
echo "----> Setting default terminal to Tilix"
update-alternatives --set x-terminal-emulator /usr/bin/tilix.wrapper &> /dev/null

#Setup VM Shared Folders
echo "----> Setup Automounting of VM Shared Folders"
mkdir -p /mnt/hgfs
echo ".host:/ /mnt/hgfs       fuse.vmhgfs-fuse        noauto,allow_other      0       0" | tee -a /etc/fstab
printf "#!/bin/bash\n\n mount /mnt/hgfs\n" > /etc/rc.local
chmod +x /etc/rc.local
cp ../resources/rc-local.service /etc/systemd/system/rc-local.service
systemctl enable rc-local &> /dev/null

#Set Dock to not need edge pressure to unhide which is a problem on VMs
echo"----> Setting the dock pressure to false for autohide"
gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false

#Setup GDM background, assumes your background image has been passed as the first argument to the script.
echo "----> Setting up GDM background based on if image was passed to script."
if [ -f "$1" ]; then
    convert $1 -filter Gaussian -blur 0x50 ./background-blur.jpg
    wget github.com/thiggy01/change-gdm-background/raw/master/change-gdm-background &> /dev/null
    chmod +x change-gdm-background
    ./change-gdm-background ./background-blur.jpg
fi

echo "I'm done, you need to untar your home directory backup and your .bashrc backup. Also use the tweaks tool to set the whitesur theme and the papirus icons if you so choose."
exit 0
