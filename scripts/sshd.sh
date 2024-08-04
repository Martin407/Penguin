#!/bin/bash

# Reinstall PAM modules for apt systems
if command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install --reinstall -y libpam-modules
else
    echo "This script is intended for systems using apt package manager."
    exit 1
fi

# SSHD configuration
SSHD_CONFIG="/etc/ssh/sshd_config"

# Backup the existing sshd_config
sudo cp $SSHD_CONFIG ${SSHD_CONFIG}.bak

# Write the new configuration to sshd_config
sudo tee $SSHD_CONFIG > /dev/null <<EOL
Protocol 2
Port 22
LoginGraceTime 60
PermitRootLogin no
StrictModes yes
PubKeyAuthentication no
AuthorizedKeysFile .ssh/authorized_keys
UsePrivilegeSeparation yes
MaxAuthTries 3
MaxSessions 3

PasswordAuthentication yes

HostbasedAuthentication no
IgnoreRhosts yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM no

PrintMotd no
PrintLastLog no
X11Forwarding no
AllowTcpForwarding no
PermitTunnel no
TCPKeepAlive no

Banner none
EOL

# Check the sshd config file
sudo sshd -t
if [ $? -eq 0 ]; then
    echo "sshd configuration is valid."
else
    echo "sshd configuration is invalid. Please check the configuration."
    exit 1
fi

echo "remember to restart sshd service when ready with 'sudo systemctl restart sshd'"
