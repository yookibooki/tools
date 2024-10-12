#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to print messages
log() {
    echo -e "\n\033[1;34m$1\033[0m"
}

# Function to check for commands
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log "$1 is not installed. Please install it before running this script."
        exit 1
    fi
}

# Check required commands
check_command dnf
check_command rpm
check_command sudo
check_command curl
check_command sed
check_command systemctl  # Add systemctl to the check

# DEFAULT
log "Removing Firefox and updating the system..."
sudo dnf -y remove firefox
sudo dnf -y update
sudo dnf -y install epel-release
sudo dnf config-manager --set-enabled crb

# Update PATH in .bashrc
if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    log "Updated PATH in ~/.bashrc."
fi
source ~/.bashrc

# BRAVE
log "Installing Brave browser..."
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf -y install brave-browser

# GO 1.23.2
log "Downloading and installing Go 1.23.2..."
curl -s -O https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz
sudo rm -f go1.23.2.linux-amd64.tar.gz  # Clean up
sudo ln -s /usr/local/go/bin/go /usr/bin/go  # Create symlink for go

# POSTGRESQL 17
log "Installing PostgreSQL 17..."
sudo dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf -y install postgresql17-server
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb

# DOCKER
log "Installing Docker..."
sudo dnf -y install yum-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# VS CODE
log "Installing Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf -y install code

# PYTHON 3.12
log "Installing Python 3.12..."
sudo dnf -y install python3.12
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
sudo alternatives --config python3

# Enable Hibernation
log "Creating a new swap file of size 16 GB..."
# Turn off the current swap if it exists
sudo swapoff -a || true  # Ignore errors if there's no swap

# Create a new swap file
sudo fallocate -l 16G /swapfile  # Create a 16 GB swap file
sudo chmod 600 /swapfile        # Set proper permissions
sudo mkswap /swapfile           # Make the file usable as swap

# Turn the new swap file on
sudo swapon /swapfile

# Make it permanent
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab > /dev/null

# Set the correct parameters for hibernation
UUID=$(sudo blkid -s UUID -o value /swapfile)  # Use the swap file for UUID
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash resume=UUID=$UUID\"" | sudo tee -a /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
log "Hibernation configured with a new 16 GB swap file."

# Create a script to check versions after reboot, and clean up the cron job
log "Creating version check script..."
cat << 'EOF' | sudo tee /usr/local/bin/check_versions.sh > /dev/null
#!/bin/bash

echo "Checking installed versions:"
echo "Docker version: $(docker --version)"
echo "PostgreSQL version: $(psql --version)"  # Correct command for checking PostgreSQL version
echo "Brave version: $(brave-browser --version)"
echo "Go version: $(go version)"
echo "Python version: $(python3 --version)"

# Remove this script
rm -- "$0"

# Remove the cron job entry to prevent it from running on future reboots
sed -i '\|check_versions.sh|d' /etc/crontab  # Use more specific matching for the cron job
EOF

# Make the version check script executable
sudo chmod +x /usr/local/bin/check_versions.sh

# Schedule version check script to run after reboot
echo "@reboot root /usr/local/bin/check_versions.sh" | sudo tee -a /etc/crontab > /dev/null

log "Rebooting the system to apply changes..."
read -p "Do you want to reboot now? (y/n) " choice
if [[ "$choice" == [Yy] ]]; then
    sudo reboot
else
    log "Please remember to reboot the system later to apply changes."
fi
