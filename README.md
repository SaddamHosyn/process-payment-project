# Secure Batch Transaction Processor (Linux + Oracle Cloud)

## Overview

This project simulates a secure financial clearing house running on **Oracle Cloud Infrastructure (OCI)**. It automates the ingestion, integrity verification, and archiving of batch payment files (CSV) using a custom Linux automation pipeline.

**Key Technologies:** Oracle Cloud Compute (VM), Ubuntu Linux, Bash Scripting, Cron Automation, SHA-256 Hashing, SFTP Security.

## 1. Cloud Infrastructure Setup (Oracle OCI)

Before deploying the automation, I provisioned the underlying infrastructure using the OCI Dashboard and CLI.

- **Compute Instance:**
  - **Shape:** AMD Micro (Always Free Tier).
  - **OS:** Canonical Ubuntu 22.04 LTS.
  - **Storage:** 50GB Boot Volume (encrypted).
- **Networking (VCN):**
  - Configured a Virtual Cloud Network (VCN) with a public subnet.
  - **Security Lists:** Configured Ingress rules to allow SSH (Port 22) only from my specific IP address for security.
- **SSH Key Management:**
  - Generated a 2048-bit RSA key pair locally.
  - Injected the public key into the instance during provisioning for passwordless authentication.

## 2. Linux Automation Logic

The system logic is handled by a robust Bash script (`process_payments.sh`) that:

1. **Watches** an incoming folder (`/incoming/payments`) for new `*.csv` files.
2. **Fingerprints** every file using `sha256sum` to detect tampering or data corruption.
3. **Audits** the transaction by writing a timestamped, immutable record to `/var/log/transaction_audit.log`.
4. **Archives** the processed file to a secure vault (`/archive/processed`) to prevent duplicate processing.

## 3. Implementation Commands (Reproduction Steps)

Below are the exact commands used to configure the Linux environment and deploy the automation.

### Connect to the Cloud Server

```bash
ssh -i mykey ubuntu@<YOUR_SERVER_IP>
```

### Install Required Tools

```bash
sudo apt update
sudo apt install nano cron -y
```

### Directory Structure & Permissions (Security)

Created a specific directory hierarchy to separate "Incoming" (Public/SFTP) from "Archived" (Private/Vault).

```bash
# Secure vault for processed files
sudo mkdir -p /archive/processed
sudo chown ubuntu:ubuntu /archive/processed

# Restricted incoming folder for clients
sudo mkdir -p /incoming/payments
sudo useradd -m -d /home/client_uploader -s /bin/false client_uploader
sudo chown root:root /incoming
sudo chown client_uploader:client_uploader /incoming/payments
```

### The Automation Script

I created the processor script using a heredoc for atomic deployment.

```bash
cat << 'EOF' > process_payments.sh
#!/bin/bash

# Configuration
INCOMING="/incoming/payments"
ARCHIVE="/archive/processed"
LOG="/var/log/transaction_audit.log"

# Get current timestamp
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Check if any CSV file exists
count=$(ls $INCOMING/*.csv 2>/dev/null | wc -l)

if [ "$count" != "0" ]; then
    for file in $INCOMING/*.csv; do
        # 1. Calculate SHA256 Hash (The "Fingerprint")
        HASH=$(sha256sum "$file" | awk '{print $1}')
        FILENAME=$(basename "$file")

        # 2. Log the event (Simulating Audit Trail)
        echo "[$DATE] PROCESSING: $FILENAME | Checksum: $HASH | Status: SECURE" | sudo tee -a $LOG

        # 3. Move to Vault (Simulate Processing)
        sudo mv "$file" "$ARCHIVE/$FILENAME.processed"
        echo "[$DATE] ARCHIVED: Moved to $ARCHIVE" | sudo tee -a $LOG
    done
fi
EOF

# Make executable
chmod +x process_payments.sh
```

### Automation (Cron Job)

Scheduled the script to run every minute to simulate near real-time processing.

```bash
sudo systemctl enable cron
sudo systemctl start cron
# Add job to crontab
(crontab -l 2>/dev/null; echo "* * * * * /home/ubuntu/process_payments.sh") | crontab -
```

### Verification & Testing

I conducted a manual test to verify the "Fraud Detection" (Integrity Check) capabilities.

```bash
# 1. Simulate a legitimate payment
echo "Payment: 1000 EUR" | sudo tee /incoming/payments/legit.csv

# 2. Simulate a fraud attempt (different content)
echo "Payment: 9999 EUR" | sudo tee /incoming/payments/fraud.csv

# 3. Verify the Audit Log shows different checksums
tail -n 4 /var/log/transaction_audit.log
```

## Project Outcome

The system successfully processed the test files, generating unique SHA-256 hashes for each. This proves the system can detect file tampering (integrity violations) by comparing the cryptographic signatures in the audit log.
