#!/bin/bash

# 1. Define variables
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="db_backup_${TIMESTAMP}.sql.gz"
S3_BUCKET="s3://voting-app-dr-backup-maddy-2026"

#Extract and compressing the database from the Docker container 
echo "Extracting database from container..."
sudo docker exec example-voting-app-db-1 pg_dump -U postgres | gzip > ${BACKUP_FILE}

#Upload the compressed backup to your S3 bucket
echo "Uploading to S3..."
/usr/local/bin/aws s3 cp ${BACKUP_FILE} ${S3_BUCKET}/

#Clean up the local file to save disk space
echo "Cleaning up local file..."
rm ${BACKUP_FILE}

echo "Backup complete!"
