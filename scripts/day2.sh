#!/bin/bash

read -p "Enter the password to set for all users: " -s pass
# Change all local passwords to the same string
for i in $(cut -d: -f1 /etc/shadow); do
    echo -e "$pass\n$pass" | passwd $i
done


directories=("etc" "home" "usr" "opt" "root" "var/www" "lib" "bin" "sbin" "srv" "mnt" "snap")

# Loop through each directory
for DIR in "${directories[@]}"; do
  cp -r /$DIR /backup-$DIR
  # Remove the directory if it exists
  rm -rf /mnt/lib64/{upper,work}/$DIR
  
  # Create the necessary directories
  mkdir -p /mnt/lib64/{upper,work}/$DIR
  
  # Mount the directory using the overlay filesystem
  mount -t overlay overlay -o lowerdir=/$DIR,upperdir=/mnt/lib64/upper/$DIR,workdir=/mnt/lib64/work/$DIR,ro /$DIR
done