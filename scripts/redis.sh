#!/bin/bash

# Function to enable Redis audit logging
enable_audit_logging() {
    echo "Enabling Redis audit logging..."

    # Add or update the slowlog-log-slower-than and slowlog-max-len options in redis.conf
    sudo sed -i "s/^# slowlog-log-slower-than .*/slowlog-log-slower-than 0/" /etc/redis/redis.conf
    sudo sed -i "s/^# slowlog-max-len .*/slowlog-max-len 128/" /etc/redis/redis.conf

    # Restart Redis to apply changes
    sudo systemctl restart redis
    echo "Redis audit logging enabled."
}

# Function to disable dangerous Redis commands
disable_dangerous_commands() {
    echo "Disabling dangerous Redis commands..."

    # List of dangerous commands
    dangerous_commands=("FLUSHDB" "FLUSHALL" "KEYS" "PEXPIRE" "DEL" "CONFIG" "SHUTDOWN" "BGREWRITEAOF" "BGSAVE" "SAVE" "SPOP" "SREM" "RENAME" "DEBUG")

    # Disable each dangerous command in redis.conf
    for cmd in "${dangerous_commands[@]}"; do
        sudo sed -i "/^rename-command $cmd/d" /etc/redis/redis.conf
        echo "rename-command $cmd \"\"" | sudo tee -a /etc/redis/redis.conf
    done

    # Restart Redis to apply changes
    sudo systemctl restart redis
    echo "Dangerous Redis commands disabled."
}

# Function to require a password for Redis
require_password() {
    echo "Requiring password for Redis..."

    # Prompt for a strong password
    read -sp "Enter a strong password for Redis: " password
    echo

    # Add or update the requirepass option in redis.conf
    sudo sed -i "s/^# requirepass .*/requirepass $password/" /etc/redis/redis.conf

    # Restart Redis to apply changes
    sudo systemctl restart redis
    echo "Password requirement for Redis enabled."
}

# Apply Redis security configurations
enable_audit_logging
disable_dangerous_commands
require_password

echo "Redis server security configurations applied."