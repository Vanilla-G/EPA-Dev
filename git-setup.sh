#!/bin/bash
# This script is used to set up the Git environment for the EPA-Dev project.
# The log file path is specified below.

LOG_FILE="/var/log/script-execution.log"

# Function to check the exit status of the last executed command
# then read from standard input and write to standard output and files append

check_exit_status() {
    if [ $? -ne 0 ]; then
        echo -e "\e[31mError: $1 failed.\e[0m" | tee -a $LOG_FILE #red
        exit 1
    else
        echo -e "\e[32m$1 succeeded.\e[0m" | tee -a $LOG_FILE #green
    fi
}

# Different Cloud Providers hae different default usernames, using whoami to address this
sudo touch $LOG_FILE
sudo chown $(whoami):$(whoami) /var/log/script-execution.log


# Server boot time into logs
sudo uptime > $LOG_FILE

# Update package lists
sudo echo "Running apt update..." | tee -a $LOG_FILE
sudo apt update -y
check_exit_status "apt update"

# Upgrade installed packages
sudo echo "Running apt upgrade..." | tee -a $LOG_FILE
sudo apt upgrade -y
check_exit_status "apt upgrade"

# Checking if the directory exists before cloning the GitHub repository
#if [ ! -d "/home/ubuntu/EPA-Dev-AWS" ]; then
#    sudo mkdir -p /home/ubuntu/EPA-Dev-AWS
#fi
#check_exit_status "Creating directory /home/ubuntu/EPA-Dev-AWS"

# Clone the GitHub repository
#sudo echo "Cloning GitHub repository..." | tee -a $LOG_FILE
#sudo git clone https://github.com/Vanilla-G/EPA-Dev-AWS.git /home/ubuntu/EPA-Dev-AWS
#check_exit_status "Cloning GitHub repository"

# Change permissions of the cloned repository
sudo echo "Changing permissions of the cloned repository..." | tee -a $LOG_FILE
sudo chmod -R 755 /home/ubuntu/EPA-Dev-AWS
check_exit_status "Changing permissions of the cloned repository"

# Run lemp-setup.sh script
#sudo echo "Running /home/ubuntu/EPA-Dev-AWS/lemp-setup.sh..." | tee -a $LOG_FILE
#sudo bash /home/ubuntu/EPA-Dev-AWS/lemp-setup.sh
#check_exit_status "Run /home/ubuntu/EPA-Dev-AWS/lemp-setup.sh"


