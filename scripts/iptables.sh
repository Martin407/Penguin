#!/bin/bash

# Flush existing iptables rules
sudo iptables-save > /etc/iptables-rules.old
sudo iptables -F
sudo iptables -X


sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT


# Allow ICMP traffic
sudo iptables -A INPUT -p icmp -j ACCEPT
sudo iptables -A OUTPUT -p icmp -j ACCEPT

# Allow SMTP traffic outbound
sudo iptables -A OUTPUT -p tcp --dport 25 -j ACCEPT


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
        sudo iptables -A OUTPUT -p tcp --sport "$port" -j ACCEPT
    else
        echo "Invalid port: $port. Skipping..."
    fi
done

sudo iptables -A OUTPUT -j LOG
sudo iptables -A INPUT -j LOG

# Save the iptables rules
if command -v iptables-save &> /dev/null; then
    sudo iptables-save > /etc/iptables-rules
else
    echo "iptables-save command not found. Please ensure iptables-persistent is installed to save rules."
fi

echo "Iptables rules have been configured."