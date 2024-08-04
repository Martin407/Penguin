#!/bin/bash

# Stop cron services
systemctl stop cron crond at anacron

# Remove SSH files
rm -rf /home/*/.ssh
rm -rf /root/.ssh

# Remove bashrc files
rm -rf /home/*/.bashrc
rm -rf /root/.bashrc

# Remove sudoedit
rm -f $(which sudoedit)

# Change permissions on pkexec
chmod 0755 /usr/bin/pkexec

# Change sudoers file
echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers
rm -f /etc/sudoers.d/*

# Prompt for each user to change password and shell
read -p "Enter the password to set for all users: " -s pass
echo
while IFS=: read -r username _; do
    if [ "$username" != "root" ]; then
        read -p "Do you want to change the password for user $username? (y/n): " change_pass
        if [ "$change_pass" == "y" ]; then
            echo -e "$pass\n$pass" | passwd $username
        fi

        read -p "Do you want to change the shell for user $username? (y/n): " change_shell
        if [ "$change_shell" == "y" ]; then
            read -p "Enter the new shell for user $username: " new_shell
            usermod -s "$new_shell" $username
        fi
    fi
done < /etc/passwd

# Change all local passwords to the same string
for i in $(cut -d: -f1 /etc/shadow); do
    echo -e "$pass\n$pass" | passwd $i
done

# If SSH is not a scored service, purge the shells
for i in $(cut -d: -f1 /etc/passwd | grep -v root); do
    usermod -s /bin/false $i
done