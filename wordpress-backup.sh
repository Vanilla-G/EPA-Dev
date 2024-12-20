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

# Step 1: Create a database dump using mysqldump to backup the WordPress database
echo "Creating database dump..."  
if ! sudo mysqldump -h "$rds_endpoint" -u "$db_username" -p"$db_password" "$db_username" | sudo tee wordpress-db-dump.sql; then
  # If mysqldump fails, the script will terminate and show an error message
  echo "Error: Database dump failed." >&2
  exit 1
fi
echo "Database dump created successfully."  # Confirmation message if the dump is created successfully

# Step 2: Clone the specified repository to a temporary directory for backup
echo "Cloning the repository..."  
rm -rf "$working_dir"  # Delete any previous backup in the working directory to ensure a clean start
if ! git clone "$repo_url" "$working_dir"; then
  # If git cloning fails, the script will terminate and show an error message
  echo "Error: Failed to clone the repository." >&2
  exit 1
fi
echo "Repository cloned successfully."  # Confirmation message if cloning succeeds

# Step 3: Copy the WordPress content and database dump into the cloned repository
echo "Adding database dump and web content to the repository..."
if ! sudo cp wordpress-db-dump.sql "$working_dir/"; then
  # If copying the SQL dump fails, the script will terminate and show an error message
  echo "Error: Failed to copy database dump." >&2
  exit 1
fi
if ! sudo cp -r /var/www/html/* "$working_dir/"; then
  # If copying the WordPress files fails, the script will terminate and show an error message
  echo "Error: Failed to copy WordPress files." >&2
  exit 1
fi

# Step 4: Commit and push the changes (new files) to the GitHub repository
cd "$working_dir" || exit  # Change to the working directory, exit if directory is not found
if ! git add .; then
  # If adding files to git fails, the script will terminate and show an error message
  echo "Error: Failed to add files to git." >&2
  exit 1
fi
if ! git commit -m "Automated backup: $(date +'%Y-%m-%d %H:%M:%S')"; then
  # If commit fails, the script will terminate and show an error message
  echo "Error: Failed to commit changes." >&2
  exit 1
fi
if ! git push origin main; then
  # If git push fails, the script will terminate and show an error message
  echo "Error: Failed to push changes to the repository." >&2
  exit 1
fi
echo "Backup completed successfully and pushed to the repository."  # Confirm the backup was completed and changes were pushed to GitHub
