#!/bin/bash

# Cron job setup (run this script separately to schedule the backup)
CRON_JOB="*/30 * * * * /home/ubuntu/EPA-Dev-AWS/wordpress-backup.sh >> /var/log/script-execution.log"
CRON_EXISTS=$(crontab -l | grep -F "$CRON_JOB")

if [ -z "$CRON_EXISTS" ]; then
  echo "Adding cron job to run backup daily at 2 AM."
  (crontab -l; echo "$CRON_JOB") | crontab -
else
  echo "Cron job already exists."
fi
