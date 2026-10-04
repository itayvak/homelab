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
#
# Each service is backed up twice: once to the local repo, then once to an
# offsite repo on itayvak-backlab (reached over Tailscale), so backups
# survive losing the homelab machine entirely. See .docs/backups/index.md.
# ===========================================================================

BACKLAB_REPO_ROOT="ssh://itayvak@itayvak-backlab/storage/backups"
HOMELAB_REPO_ROOT="/apps/storage/backups"

# backup Vaultwarden
/apps/deploy/.scripts/create-backup-borg.sh "$HOMELAB_REPO_ROOT/vaultwarden" /apps/data/vaultwarden/
/apps/deploy/.scripts/create-backup-borg.sh "$BACKLAB_REPO_ROOT/vaultwarden" /apps/data/vaultwarden/
# backup SiYuan
/apps/deploy/.scripts/create-backup-borg.sh "$HOMELAB_REPO_ROOT/siyuan" /apps/data/siyuan/
/apps/deploy/.scripts/create-backup-borg.sh "$BACKLAB_REPO_ROOT/siyuan" /apps/data/siyuan/
# backup Immich
/apps/deploy/.scripts/create-backup-borg.sh "$HOMELAB_REPO_ROOT/immich" /apps/storage/media/immich/
/apps/deploy/.scripts/create-backup-borg.sh "$BACKLAB_REPO_ROOT/immich" /apps/storage/media/immich/
