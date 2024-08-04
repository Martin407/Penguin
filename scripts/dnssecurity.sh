#!/bin/bash

# Function to enable query logging for BIND9
enable_query_logging_bind9() {
    echo "Enabling query logging for BIND9..."

    # Check if the logging section already exists
    if ! grep -q "logging {" /etc/bind/named.conf; then
        sudo tee -a /etc/bind/named.conf > /dev/null <<EOL
logging {
    channel query_log {
        file "/var/log/named/query.log" versions 3 size 5m;
        severity info;
        print-time yes;
    };
    category queries { query_log; };
};
EOL
    fi

    # Ensure the log directory exists and set permissions
    sudo mkdir -p /var/log/named
    sudo touch /var/log/named/query.log
    sudo chown bind:bind /var/log/named/query.log
    sudo chmod 640 /var/log/named/query.log

    # Restart BIND9 to apply changes
    sudo systemctl restart bind9
    echo "Query logging enabled for BIND9."
}

# Function to enable query logging for dnsmasq
enable_query_logging_dnsmasq() {
    echo "Enabling query logging for dnsmasq..."

    # Add or update the log-queries option in dnsmasq configuration
    if ! grep -q "^log-queries" /etc/dnsmasq.conf; then
        echo "log-queries" | sudo tee -a /etc/dnsmasq.conf
    fi

    # Restart dnsmasq to apply changes
    sudo systemctl restart dnsmasq
    echo "Query logging enabled for dnsmasq."
}

# Function to identify and make DNS files read-only
make_dns_files_read_only() {
    echo "Making DNS files read-only..."

    # Identify DNS files for BIND9
    if [ -d "/etc/bind" ]; then
        sudo find /etc/bind -type f -exec chmod 444 {} \;
        echo "DNS files in /etc/bind made read-only."
    fi

    # Identify DNS files for dnsmasq
    if [ -d "/etc/dnsmasq.d" ]; then
        sudo find /etc/dnsmasq.d -type f -exec chmod 444 {} \;
        echo "DNS files in /etc/dnsmasq.d made read-only."
    fi

    echo "DNS files have been made read-only."
}

# Determine the system type and enable query logging accordingly
if command -v apt &> /dev/null; then
    if systemctl is-active --quiet bind9; then
        enable_query_logging_bind9
    elif systemctl is-active --quiet dnsmasq; then
        enable_query_logging_dnsmasq
    else
        echo "No supported DNS server (BIND9 or dnsmasq) found running on this system."
        exit 1
    fi
elif command -v yum &> /dev/null; then
    if systemctl is-active --quiet named; then
        enable_query_logging_bind9
    elif systemctl is-active --quiet dnsmasq; then
        enable_query_logging_dnsmasq
    else
        echo "No supported DNS server (BIND9 or dnsmasq) found running on this system."
        exit 1
    fi
else
    echo "Unsupported system. This script supports Ubuntu and CentOS."
    exit 1
fi

# Make DNS files read-only
make_dns_files_read_only