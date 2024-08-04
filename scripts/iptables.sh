#!/bin/bash

# Function to prompt for yes/no
prompt_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Flush existing iptables rules
sudo iptables -F
sudo iptables -X

# Allow loopback traffic
if prompt_yes_no "Do you want to allow loopback traffic (in/out)?"; then
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT
fi

# Allow ICMP traffic
if prompt_yes_no "Do you want to allow ICMP traffic (in/out)?"; then
    sudo iptables -A INPUT -p icmp -j ACCEPT
    sudo iptables -A OUTPUT -p icmp -j ACCEPT
fi

# Allow DNS traffic outbound
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow HTTP/HTTPS traffic outbound
sudo iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Prompt for ports to allow inbound
read -p "Enter the ports you want to allow inbound (comma separated): " ports
IFS=',' read -ra PORT_ARRAY <<< "$ports"
for port in "${PORT_ARRAY[@]}"; do
    if [[ "$port" =~ ^[0-9]+$ ]]; then
        sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
    else
        echo "Invalid port: $port. Skipping..."
    fi
done

sudo iptables -A OUTPUT -j LOG
sudo iptables -A INPUT -j LOG

# Save the iptables rules
if command -v iptables-save &> /dev/null; then
    sudo iptables-save > /etc/iptables/rules.v4
else
    echo "iptables-save command not found. Please ensure iptables-persistent is installed to save rules."
fi

echo "Iptables rules have been configured."