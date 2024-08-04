#!/bin/bash

# List of common services to protect
services=("bind9" "sshd" "apache2" "httpd" "nginx" "mysqld", "mariadb", "redis", "redisd")

# Function to install and setup AppArmor
setup_apparmor() {
    echo "Setting up AppArmor..."

    # Install AppArmor
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y apparmor apparmor-utils
    elif command -v yum &> /dev/null; then
        sudo yum install -y apparmor apparmor-utils
    else
        echo "Neither apt nor yum package manager found. Cannot install AppArmor."
        exit 1
    fi

    # Enable AppArmor
    sudo systemctl enable apparmor
    sudo systemctl start apparmor

    # Load AppArmor profiles in complain mode
    sudo aa-complain /etc/apparmor.d/*

    echo "AppArmor is set up in audit mode. To move to enforcing mode, run:"
    echo "sudo aa-enforce /etc/apparmor.d/*"

    # Set up auditing for services
    for service in "${services[@]}"; do
        sudo aa-logprof /usr/sbin/$service
    done
}

# Function to install and setup SELinux
setup_selinux() {
    echo "Setting up SELinux..."

    # Install SELinux
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y selinux-basics selinux-policy-default auditd
        sudo selinux-activate
    elif command -v yum &> /dev/null; then
        sudo yum install -y selinux-policy selinux-policy-targeted policycoreutils
        sudo setenforce 0
    else
        echo "Neither apt nor yum package manager found. Cannot install SELinux."
        exit 1
    fi

    # Set SELinux to permissive mode
    sudo setenforce 0

    echo "SELinux is set up in audit mode. To move to enforcing mode, run:"
    echo "sudo setenforce 1"

    # Set up auditing for services
    for service in "${services[@]}"; do
        sudo audit2allow -a -M $service
        sudo semodule -i ${service}.pp
    done
}

# Determine if the system uses AppArmor or SELinux
if command -v apparmor_status &> /dev/null; then
    setup_apparmor
elif command -v sestatus &> /dev/null; then
    setup_selinux
else
    echo "Neither AppArmor nor SELinux detected. Please install one of them manually."
    exit 1
fi