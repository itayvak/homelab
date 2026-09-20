#!/bin/bash

# ===========================================================================
# run-backup.sh
#
# Backs up all folders I want in my homelab. Runs on a cron schedule every day
# at 3 AM, from itayvak's crontab.
# Using this script instead of putting separate commands in crontab makes sure
# every command waits for the other to finish, and these backups take a long
# time to finish.
#
# The small backups run first, so they don't wait behind the long Immich one.
# ===========================================================================

# backup Vaultwarden
/apps/deploy/.scripts/create-backup-borg.sh /apps/storage/backups/vaultwarden /apps/data/vaultwarden/
# backup SiYuan
/apps/deploy/.scripts/create-backup-borg.sh /apps/storage/backups/siyuan /apps/data/siyuan/
# backup Immich
/apps/deploy/.scripts/create-backup-borg.sh /apps/storage/backups/immich/ /apps/storage/media/immich/
