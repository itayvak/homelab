#!/bin/bash

# ===========================================================================
# run-backup.sh
# Backups all folders I want in my homelab. Runs on a Cron schedule every day
# at 3 AM.
# ===========================================================================

# backup Immich
/apps/deploy/.scripts/create-backup-borg.sh /apps/storage/backups/immich/ /apps/storage/media/immich/