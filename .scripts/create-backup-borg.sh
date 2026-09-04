#!/bin/bash

# ===========================================================================
# create-backup-borg.sh
#
# A helper script that creates a Borg archive, prunes and compacts the repository.
#
# Usage:
#   create-backup-borg <borg-repository> <source-directory>
# ===========================================================================

# Exit immediately if any command fails
set -e
# Treat unset variables as errors
set -u
# Make pipelines fail if any command in the pipeline fails
set -o pipefail

# ---- Generic Borg backup script ----
#
# Usage:
#  create-backup-borg <repository> <srouce_driectory>

# Validate arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <borg-repository> <source-directory>"
    exit 1
fi

# Input Borg passphrase
export BORG_PASSCOMMAND='cat /apps/secrets/borg-passphrase'

# Parameters
BORG_REPO="$1"
BACKUP_DIR="$2"

# Validate source directory
if [ ! -d "$BACKUP_DIR" ]; then
    echo "ERROR: Backup directory does not exist:"
    echo "  $BACKUP_DIR"
    exit 1
fi

# Validate Borg repository
if [ ! -d "$BORG_REPO" ]; then
    echo "ERROR: Borg repository does not exist:"
    echo "  $BORG_REPO"
    exit 1
fi

echo "Creating Borg archive..."
borg create \
    --verbose \
    --stats \
    --compression zstd,6 \
    "$BORG_REPO::backup-{now:%Y-%m-%d_%H-%M-%S}" \
    "$BACKUP_DIR"


echo "Pruning old archives..."
borg prune \
    --list \
    --stats \
    --keep-daily=7 \
    --keep-weekly=3 \
    --keep-monthly=3 \
    "$BORG_REPO"

# Compact the repository -
# After pruning, some repository segments may contain data that is no longer referenced by any archive
echo "Compacting Borg repository..."
borg compact "$BORG_REPO"

echo "Borg backup completed successfully."
