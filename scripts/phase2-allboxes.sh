#!/bin/bash

# Check if auditd is installed
if ! command -v auditd &> /dev/null; then
    echo "auditd is not installed. Installing auditd..."

    # Determine the package manager and install auditd
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y auditd
    elif command -v yum &> /dev/null; then
        sudo yum install -y auditd
    else
        echo "Neither apt nor yum package manager found. Cannot install auditd."
        exit 1
    fi
else
    echo "auditd is already installed."
fi

# Add auditd rules for tracking commands ran
auditctl -a exit,always -F arch=b64 -F euid=0 -S execve -k audit-wazuh-c
auditctl -a exit,always -F arch=b32 -F euid=0 -S execve -k audit-wazuh-c
auditctl -a exit,always -F arch=b64 -F euid!=0 -S execve -k audit-wazuh-c
auditctl -a exit,always -F arch=b32 -F euid!=0 -S execve -k audit-wazuh-c

# Enable auditd if not already enabled
auditctl -e 1

# Instructions to view the logs
echo "To view the logs: ausearch -k audit-wazuh-c | grep argc"

# Run package integrity checkers based on the distribution
if command -v rpm &> /dev/null; then
    echo "Running package integrity check for Redhat-based systems..."
    rpm -Va
elif command -v debsums &> /dev/null; then
    echo "Running package integrity check for Debian-based systems..."
    debsums -ac
elif command -v paccheck &> /dev/null; then
    echo "Running package integrity check for Arch-based systems..."
    paccheck --md5sum --quiet
else
    echo "No package integrity checker found for your distribution."
fi