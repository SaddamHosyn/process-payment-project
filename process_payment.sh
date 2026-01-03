ubuntu@Crosskey-Lab-Micro:~$ cat process.sh
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
