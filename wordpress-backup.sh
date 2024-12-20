#!/bin/bash

# Set up necessary variables for authentication and configuration

gittoken=GH_TOKEN                # GitHub Personal Access Token used for authentication with GitHub (should be securely stored in environment)
gitusername=GH_USERNAME          # GitHub Username (also stored securely, such as in environment variables)

# Define the working directory where the repository will be cloned
working_dir="/tmp/epa-dev-backup"   # Temporary directory for repository clone and backup files
repo_url=S_REPO_URL               # GitHub repository URL where files will be uploaded (should be defined before running the script)

# Define RDS and database credentials for database export
rds_endpoint=S_RDS_ENDPOINT       # The endpoint for your AWS RDS instance (set as an environment variable or directly in the script)
db_username=S_DB_USER            # The database username used to connect to the RDS instance
dbpassword=S_DB_PASSWORD         # The password for the database user

#Create a database dump using mysqldump to backup the WordPress database
echo "Creating database dump..."  
sudo mysqldump -h "$rds_endpoint" -u "$db_username" -p"$db_password" "$db_username" > wordpress-db-dump.sql
if [ $? -ne 0 ]; then
  # If mysqldump fails (e.g., due to incorrect credentials or connection issues), the script will terminate and show an error message
  echo "Error: Database dump failed." >&2
  exit 1
fi
echo "Database dump created successfully."  # If the dump succeeds, display a confirmation message

#Clone the specified repository to a temporary directory for backup
echo "Cloning the repository..."  
rm -rf "$working_dir"  # Delete any previous backup in the working directory to ensure a clean start
git clone "$repo_url" "$working_dir"  # Clone the repository from GitHub into the working directory
if [ $? -ne 0 ]; then
  # If git cloning fails (e.g., due to authentication or URL issues), the script will terminate and show an error message
  echo "Error: Failed to clone the repository." >&2
  exit 1
fi
echo "Repository cloned successfully."  # If cloning succeeds, display a confirmation message

#Copy the WordPress content and database dump into the cloned repository
echo "Adding database dump and web content to the repository..."
sudo cp wordpress-db-dump.sql "$working_dir/"  # Copy the SQL dump file into the working directory (GitHub repository)
sudo cp -r /var/www/html/* "$working_dir/"     # Copy all files from the WordPress site's root directory into the working directory
if [ $? -ne 0 ]; then
  # If copying the files fails (e.g., due to permission issues), the script will terminate and show an error message
  echo "Error: Failed to copy files." >&2
  exit 1
fi

#Commit and push the changes (new files) to the GitHub repository
cd "$working_dir" || exit  # Change to the working directory, exit if directory is not found
git add .  # Stage all new and modified files to be included in the commit
git commit -m "Automated backup: $(date +'%Y-%m-%d %H:%M:%S')"  # Commit the changes with a message including the timestamp
git push origin main  # Push the commit to the 'main' branch of the repository
if [ $? -ne 0 ]; then
  # If git push fails (e.g., due to authentication or network issues), the script will terminate and show an error message
  echo "Error: Failed to push changes to the repository." >&2
  exit 1
fi
echo "Backup completed successfully and pushed to the repository."  # Confirm the backup was completed and changes were pushed to GitHub
