# Resilient Cloud Microservices with Automated Cross-Region Disaster Recovery & Observability

An enterprise-ready cloud deployment featuring a containerized microservices application hosted on AWS EC2, monitored via Prometheus and Grafana, and protected by an automated, cross-region S3 disaster recovery pipeline using passwordless IAM authentication.

---

## Architecture Overview

```text
               +-------------------------------------------------------+
               |                     AWS EC2 (Ubuntu)                  |
               |                                                       |
               |   [ Client Traffic ] ---> [ Web & Worker Services ]   |
               |                                      |                |
               |                                      v                |
               |                              [ PostgreSQL DB ]        |
               |                                      |                |
               |           +--------------------------+                |
               |           |                                           |
               |           v                                           |
               |   [ Cron Automation ]                                 |
               |           |                                           |
               |           v                                           |
               |   [ s3-backup.sh ]                                    |
               |   (AWS CLI + IAM Role)                                |
               +-----------|-------------------------------------------+
                           |
                           | Encrypted Transfer (HTTPS)
                           v
               +-------------------------------------------------------+
               |              AWS S3 Bucket (Cross-Region)             |
               |                                                       |
               |   s3://voting-app-backup-tokyo-2026/                  |
               |   └── db-backup-YYYY-MM-DD.sql.gz                     |
               +-------------------------------------------------------+
```
**KEY TECHNICAL FEATURES**

- Multi-Container Microservices Architecture: Deployed voting, result, and worker services backed by PostgreSQL and Redis using Docker Compose.
  
- Observability & Telemetry: Full-stack metric scraping using Prometheus, Node Exporter, and cAdvisor, visualized through Grafana (Dashboard 1860) for real-time memory, CPU, and container health monitoring.
  
- Automated Disaster Recovery (DR): Custom Bash automation script scheduled via Linux cron to generate compressed PostgreSQL dumps (.sql.gz) and sync them to an off-region Amazon S3 bucket.
  
- Zero-Credential Security Architecture: Implemented AWS IAM Instance Profiles (voting-app-s3-backup-role) to allow EC2 to stream backups to S3 without embedding long-lived AWS Access Keys or secrets in code or environment variables.
  
- Low-Cost High-Resilience Engineering: Built within AWS Free Tier guardrails, leveraging localized swap memory configurations and lean EBS storage allocations ($< \$0.50$ operational cost).

**PRODUCTION INCIDENT ENGINEERING & OPERATIONAL TUNING**

__1. PostgreSQL Out-Of-Memory (OOM) Resolution__

- Problem: During metric collection spikes, Linux kernel OOM Killer terminated the PostgreSQL container due to micro-instance hardware constraints.

- Root-Cause Analysis: The instance ran with zero swap allocation, leaving no buffer when Prometheus and database worker processes peaked simultaneously.

- Mitigation: Provisioned a persistent 2 GB virtual swap file (/swapfile), configured swapiness parameters, and stabilized database uptime to 100%.

__2. Passwordless IAM Role Provisioning__

- Design Decision: Avoided using static AWS Access Keys in scripts to mitigate credential leak vulnerabilities.

- Implementation: Configured an IAM Instance Profile attached directly to the EC2 host with an S3 write/read policy, offloading authentication directly to the AWS Instance Metadata Service (IMDS).

**DISASTER RECOVERY DRILL: ZERO DATA LOSS VALIDATION**

A full disaster recovery drill was executed to validate Recovery Time Objective (RTO) and Recovery Point Objective (RPO):

- State Snapshot: Production votes recorded in the database.

- Disaster Simulation: The active database container volume was forcefully purged (DROP TABLE votes; simulation).

- Restoration Execution: The latest archive was pulled directly from the cross-region S3 bucket, uncompressed, and piped back into PostgreSQL:

  aws s3 cp s3://<backup-bucket>/<latest-backup>.sql.gz - | gunzip | docker exec -i <db-container> psql -U postgres

- Validation: Confirmed 100% data integrity with identical vote counts verified through CLI query logs.

***INFRASTRUCTURE VERIFICATION***

- Application Frontend
- Grafana Telemetry & Hardware Monitoring
- IAM Instance Role Security Configuration
- S3 Cross-Region Backup Vault
- Disaster Recovery Restore Verification

**HOW TO DEPLOY**

- Clone the repository:

  git clone [https://github.com/](https://github.com/)<your-username>/<your-repo-name>.git
cd <your-repo-name>

- Launch services:

  docker compose up -d

- Configure backup automation:

  chmod +x scripts/s3-backup.sh
(crontab -l 2>/dev/null; echo "0 0 * * * /home/ubuntu/scripts/s3-backup.sh") | crontab -


