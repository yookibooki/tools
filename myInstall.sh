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
check_command wget
check_command dnf
check_command rpm
check_command sudo

# DEFAULT
log "Removing Firefox and updating the system..."
sudo dnf -y remove firefox
sudo dnf -y update
sudo dnf -y groupinstall "Development Tools"
sudo dnf -y install epel-release
sudo dnf config-manager --set-enabled crb

# Update PATH in .bashrc
if ! grep -q '/usr/local/go/bin:/opt/python/3.13.0/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin:/opt/python/3.13.0/bin' >> ~/.bashrc
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
wget -q https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz
rm -f go1.23.2.linux-amd64.tar.gz  # Clean up

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

# PYTHON 3.13
log "Installing Python 3.13..."
sudo dnf -y update
sudo dnf -y groupinstall "Development Tools"
sudo dnf -y install wget gcc openssl-devel bzip2-devel libffi-devel xz-devel tk-devel
cd /tmp/
wget -q https://www.python.org/ftp/python/3.13.0/Python-3.13.0.tgz
tar xzf Python-3.13.0.tgz
cd Python-3.13.0
sudo ./configure --prefix=/opt/python/3.13.0/ --enable-optimizations --with-lto --with-computed-gotos --with-system-ffi
sudo make -j "$(nproc)"
sudo make altinstall
cd ..
sudo rm -rf Python-3.13.0  # Clean up

# Create symlinks for Python
log "Creating symlinks for Python..."
for binary in python3.13 pip3.13 pydoc3.13 idle3.13; do
    sudo ln -sf /opt/python/3.13.0/bin/$binary /opt/python/3.13.0/bin/${binary%3.13}
done

# NVIDIA DRIVER
log "Installing NVIDIA driver..."
sudo dnf -y install kernel-devel kernel-headers gcc make
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
sudo dnf clean all
sudo dnf -y install nvidia-driver nvidia-settings
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null
sudo dracut --force

# Create a script to check versions after reboot, and clean up the cron job
log "Creating version check script..."
cat << 'EOF' | sudo tee /usr/local/bin/check_versions.sh > /dev/null
#!/bin/bash

echo "Checking installed versions:"
echo "Docker version: $(docker --version)"
echo "PostgreSQL version: $(postgresql-17 --version)"
echo "Brave version: $(brave-browser --version)"
echo "NVIDIA driver info: $(nvidia-smi)"
echo "Go version: $(go version)"
echo "Python version: $(python3 --version)"

# Remove this script
rm -- "$0"

# Remove the cron job entry to prevent it from running on future reboots
sed -i '/check_versions.sh/d' /etc/crontab
EOF

# Make the version check script executable
sudo chmod +x /usr/local/bin/check_versions.sh

# Schedule version check script to run after reboot
echo "@reboot root /usr/local/bin/check_versions.sh" | sudo tee -a /etc/crontab > /dev/null

log "Rebooting the system to apply changes..."
sudo reboot
