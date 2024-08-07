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
