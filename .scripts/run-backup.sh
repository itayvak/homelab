#!/bin/bash

# ===========================================================================
# run-backup.sh
#
# Backups all folders I want in my homelab. Runs on a Cron schedule every day
# at 3 AM.
# Using this script instead of putting seperate comamnds in crontab makes sure
# every command waits for the other to finish, and these backups take a long
# time to finish.
# ===========================================================================

# backup Immich
/apps/deploy/.scripts/create-backup-borg.sh /apps/storage/backups/immich/ /apps/storage/media/immich/
# backup Vaultwarden
/apps/deploy/.scripts/create-backup-borg.sh /apps/storage/backups/vaultwarden /apps/data/vaultwarden/