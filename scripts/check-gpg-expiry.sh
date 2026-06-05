#!/bin/bash

set -e

ALERT_DAYS=90
KEYS_DIR="keys"
TODAY_EPOCH=$(date +%s)
ALERT_SECONDS=$((ALERT_DAYS * 24 * 60 * 60))

ALERT_MESSAGE=""

echo "Checking GPG public key expiration dates..."
echo

TEMP_GNUPG_HOME=$(mktemp -d)
chmod 700 "$TEMP_GNUPG_HOME"

for key_file in "$KEYS_DIR"/*.asc; do
  echo "Checking: $key_file"

  GNUPGHOME="$TEMP_GNUPG_HOME" gpg --quiet --import "$key_file"

  KEY_INFO=$(GNUPGHOME="$TEMP_GNUPG_HOME" gpg --with-colons --list-keys)

  EXPIRY_EPOCH=$(echo "$KEY_INFO" | awk -F: '$1 == "pub" {print $7}' | tail -1)
  USER_ID=$(echo "$KEY_INFO" | awk -F: '$1 == "uid" {print $10}' | tail -1)

  if [ -z "$EXPIRY_EPOCH" ]; then
    echo "No expiry: $USER_ID"
    echo
    continue
  fi

  DAYS_LEFT=$(( (EXPIRY_EPOCH - TODAY_EPOCH) / 86400 ))

  echo "User: $USER_ID"
  echo "Days left: $DAYS_LEFT"

  if [ "$DAYS_LEFT" -le "$ALERT_DAYS" ]; then
    ALERT_MESSAGE+="WARNING: $key_file expires in $DAYS_LEFT days. User: $USER_ID"$'\n'
  fi

  echo
done

rm -rf "$TEMP_GNUPG_HOME"

if [ -n "$ALERT_MESSAGE" ]; then
  echo "Keys expiring soon:"
  echo "$ALERT_MESSAGE"
  echo "$ALERT_MESSAGE" > expiry-alert.txt
else
  echo "No keys are expiring within $ALERT_DAYS days."
  echo "No keys are expiring within $ALERT_DAYS days." > expiry-alert.txt
fi
	
