#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Update system and remove Firefox
sudo dnf -y remove firefox
sudo dnf -y update

# Install common development tools, dependencies, and the Brave Browser
sudo dnf -y groupinstall "Development Tools"
sudo dnf -y install epel-release wget gcc openssl-devel bzip2-devel libffi-devel xz-devel tk-devel dnf-plugins-core
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf install -y brave-browser

# Install Go 1.23.2
wget -q https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz
rm go1.23.2.linux-amd64.tar.gz  # Clean up

# Install PostgreSQL 17
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql17-server
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb

# Install Docker
sudo dnf install -y yum-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf install -y code

# Install Python 3.13
cd /tmp/
wget -q https://www.python.org/ftp/python/3.13.0/Python-3.13.0.tgz
tar xzf Python-3.13.0.tgz
cd Python-3.13.0
sudo ./configure --prefix=/opt/python/3.13.0/ --enable-optimizations --with-lto --with-computed-gotos --with-system-ffi
sudo make -j "$(nproc)"
sudo make altinstall
cd .. && rm -rf Python-3.13.0  # Clean up

# Create symlinks for Python and Pip
for binary in python3.13 pip3.13 pydoc3.13 idle3.13; do
    sudo ln -s /opt/python/3.13.0/bin/$binary /usr/local/bin/${binary%3.13}
done

# Install NVIDIA Driver
sudo dnf -y install kernel-devel kernel-headers make
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
sudo dnf clean all
sudo dnf -y install nvidia-driver nvidia-settings
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
sudo dracut --force
sudo reboot
