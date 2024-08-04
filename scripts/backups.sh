#!/bin/bash

# Create the backup directory
mkdir -p /backup

# Copy the specified directories to the backup directory
cp -rp /etc /var/www /home /opt /root /backup

# Make the backup directory immutable
chattr +i /backup