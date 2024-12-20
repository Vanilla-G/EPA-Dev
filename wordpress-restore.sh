#!/bin/bash

# Set up necessary variables for authentication and configuration
gittoken=GH_TOKEN                # GitHub Personal Access Token (securely stored)
gitusername=GH_USERNAME          # GitHub Username (securely stored)
working_dir="/tmp/epa-dev-restore"   # Temporary directory to clone the repository into
repo_url=S_REPO_URL               # GitHub repository URL for restoring the files (should be defined before running the script)

# Define RDS and database credentials for database import
rds_endpoint=S_DB_ENDPOINT       # The endpoint for your AWS RDS instance
db_username=S_DB_USER            # The database username to connect to the RDS instance
dbpassword=S_DB_PASSWORD         # The password for the database user

# Step 1: Clone the specified repository to a temporary directory
echo "Cloning the repository..."
rm -rf "$working_dir"  # Delete any previous data in the working directory to ensure a clean start
if ! git clone "$repo_url" "$working_dir"; then
  # If git cloning fails, the script will terminate and show an error message
  echo "Error: Failed to clone the repository." >&2
  exit 1
fi
echo "Repository cloned successfully."  # Confirmation message if cloning succeeds

# Step 2: Copy the WordPress files from the repository to /var/www/html
echo "Restoring WordPress content to /var/www/html..."
if ! sudo cp -r "$working_dir/html"/* /var/www/html/; then
  # If copying the WordPress files fails, the script will terminate and show an error message
  echo "Error: Failed to copy WordPress files to /var/www/html." >&2
  exit 1
fi
echo "WordPress files restored successfully."  # Confirmation message if copy succeeds

# Step 3: Restore the database from the dump file into the RDS instance
echo "Restoring database..."
if ! sudo cat "$working_dir/wordpress-db-dump.sql" | sudo mysql -h "$rds_endpoint" -u "$db_username" -p"$db_password" "$db_username"; then
  # If restoring the database fails, the script will terminate and show an error message
  echo "Error: Database restoration failed." >&2
  exit 1
fi
echo "Database restored successfully."  # Confirmation message if database restoration is successful

echo "Restore completed successfully."  # Final confirmation message
