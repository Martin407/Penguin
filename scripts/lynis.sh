#!/bin/bash

# Function to install Lynis on Debian-based systems
install_lynis_debian() {
    echo "Installing Lynis on Debian-based system..."

    # Import the GPG key
    curl -fsSL https://packages.cisofy.com/keys/cisofy-software-public.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/cisofy-software-public.gpg

    # Add the repository
    echo "deb [arch=amd64,arm64 signed-by=/etc/apt/trusted.gpg.d/cisofy-software-public.gpg] https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list

    # Install the 'https' method for APT if not available
    sudo apt install -y apt-transport-https

    # Refresh the local package database and install Lynis
    sudo apt update
    sudo apt install -y lynis

    # Run Lynis audit
    echo "Running Lynis audit..."
    sudo lynis audit system
}

# Function to install Lynis on CentOS-based systems
install_lynis_centos() {
    echo "Installing Lynis on CentOS-based system..."

    # Ensure that cURL, NSS, openssl, and CA certificates are up-to-date
    sudo yum update -y ca-certificates curl nss openssl

    # Create the repository file
    sudo tee /etc/yum.repos.d/cisofy-lynis.repo > /dev/null <<EOL
[lynis]
name=CISOfy Software - Lynis package
baseurl=https://packages.cisofy.com/community/lynis/rpm/
enabled=1
gpgkey=https://packages.cisofy.com/keys/cisofy-software-rpms-public.key
gpgcheck=1
priority=2
EOL

    # Import the GPG key
    sudo rpm --import https://packages.cisofy.com/keys/cisofy-software-rpms-public.key

    # Install Lynis
    sudo yum makecache fast
    sudo yum install -y lynis

    # Run Lynis audit
    echo "Running Lynis audit..."
    sudo lynis audit system
}

# Determine the system type and install Lynis accordingly
if command -v apt &> /dev/null; then
    install_lynis_debian
elif command -v yum &> /dev/null; then
    install_lynis_centos
else
    echo "Unsupported system. This script supports Debian-based and CentOS-based systems."
    exit 1
fi

echo "Lynis audit completed."