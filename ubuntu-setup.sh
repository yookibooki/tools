#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to print messages
log() {
    echo -e "\n\033[1;34m$1\033[0m"
}

# DEFAULT
log "Removing Firefox and updating the system..."
sudo apt -y autopurge firefox
sudo apt -y update
sudo apt -y install apt-transport-https ca-certificates curl software-properties-common

# Update PATH in .bashrc
if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    log "Updated PATH in ~/.bashrc."
fi
source ~/.bashrc

# BRAVE
log "Installing Brave browser..."
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt install brave-browser -y

# GO 1.23.2
log "Downloading and installing Go 1.23.2..."
curl -s -O https://golang.org/dl/go1.23.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz
sudo rm -f go1.23.2.linux-amd64.tar.gz  # Clean up

# POSTGRESQL 17
log "Installing PostgreSQL 17..."
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt -y install postgresql

# DOCKER
log "Installing Docker..."
sudo apt -y autopurge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# VS CODE
log "Installing Visual Studio Code..."
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
sudo apt install code -y

# PYTHON 3.12
log "Installing Pip3/venv..."
sudo apt install python3-venv python3-pip -y


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
sudo update-grub
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
