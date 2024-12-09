#!/bin/bash

# Log file path
LOG_FILE="/var/log/script-execution.log"

# Function to check the exit status of the last executed command
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo -e "\e[31mError: $1 failed.\e[0m" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "\e[32m$1 succeeded.\e[0m" | tee -a $LOG_FILE
    fi
}

# --- EBS Volume Setup ---
# Format the volume if not already formatted
if ! blkid /dev/sdf; then
    sudo mkfs.ext4 /dev/sdf
fi

# Create mount point for the EBS volume
sudo mkdir -p /mnt/ebs-volume
sudo mount /dev/sdf /mnt/ebs-volume

# Ensure the volume mounts automatically on reboot
echo '/dev/sdf /mnt/ebs-volume ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Move MariaDB data directory to the new volume
sudo systemctl stop mariadb
sudo rsync -avzh /var/lib/mysql/ /mnt/ebs-volume/
sudo mv /var/lib/mysql /var/lib/mysql.bak
sudo ln -s /mnt/ebs-volume /var/lib/mysql
sudo chown -R mysql:mysql /mnt/ebs-volume
sudo systemctl start mariadb

# Now move WordPress files to the EBS volume
sudo echo "Running rsync -avzh..." | tee -a $LOG_FILE
sudo rsync -avzh /var/www/html/ /mnt/ebs-volume/wordpress/   # Move WordPress files
check_exit_status "move wordpress files to EBS"


# Create symbolic link to the EBS volume
sudo echo "sybolic link mnt/ebs-volume/wordpress /var/www/html..." | tee -a $LOG_FILE
sudo ln -s /mnt/ebs-volume/wordpress /var/www/html
check_exit_status "create symlink to EBS volume"


sudo chown -R www-data:www-data /mnt/ebs-volume/wordpress
sudo chmod -R 755 /mnt/ebs-volume/wordpress



