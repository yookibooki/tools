#!/bin/bash
set -e

log() {
    echo -e "\n\033[1;34m$1\033[0m"
}

check_command() {
    command -v "$1" &> /dev/null || { log "$1 is not installed. Please install it."; exit 1; }
}

# Check required commands
for cmd in dnf rpm sudo curl sed systemctl; do
    check_command "$cmd"
done

log "Removing Firefox and updating the system..."
sudo dnf -y remove firefox && sudo dnf -y update
sudo dnf -y install epel-release
sudo dnf config-manager --set-enabled crb

# Update PATH in .bashrc
grep -q '/usr/local/go/bin' ~/.bashrc || { echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc; log "Updated PATH in ~/.bashrc."; }
source ~/.bashrc

# Install Brave
log "Installing Brave browser..."
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf -y install brave-browser

# Install Go 1.23.2
log "Downloading and installing Go 1.23.2..."
curl -s -O https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz && sudo rm -f go1.23.2.linux-amd64.tar.gz
sudo ln -s /usr/local/go/bin/go /usr/bin/go

# Install PostgreSQL 17
log "Installing PostgreSQL 17..."
sudo dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf -y install postgresql17-server
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb

# Install Docker
log "Installing Docker..."
sudo dnf -y install yum-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Visual Studio Code
log "Installing Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf -y install code

# Install Python 3.12
log "Installing Python 3.12..."
sudo dnf -y install python3.12
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
sudo alternatives --config python3

# Enable Hibernation
log "Creating a new swap file of size 16 GB..."
sudo swapoff -a || true
sudo fallocate -l 16G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab > /dev/null
UUID=$(sudo blkid -s UUID -o value /swapfile)
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash resume=UUID=$UUID\"" | sudo tee -a /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
log "Hibernation configured."

# Create version check script
log "Creating version check script..."
cat << 'EOF' | sudo tee /usr/local/bin/check_versions.sh > /dev/null
#!/bin/bash
echo "Checking installed versions:"
echo "Docker version: $(docker --version)"
echo "PostgreSQL version: $(psql --version)"
echo "Brave version: $(brave-browser --version)"
echo "Go version: $(go version)"
echo "Python version: $(python3 --version)"
rm -- "$0"
sed -i '\|check_versions.sh|d' /etc/crontab
EOF
sudo chmod +x /usr/local/bin/check_versions.sh
echo "@reboot root /usr/local/bin/check_versions.sh" | sudo tee -a /etc/crontab > /dev/null

log "Rebooting the system to apply changes..."
read -p "Do you want to reboot now? (y/n) " choice
[[ "$choice" =~ ^[Yy]$ ]] && sudo reboot || log "Please remember to reboot later."
