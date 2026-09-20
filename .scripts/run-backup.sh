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
# Vaultwarden runs first because it is small and fast, and it should not wait
# behind the long Immich backup. Every backup runs even if an earlier one
# fails, and the script exits non-zero if any of them failed.
# ===========================================================================

# Treat unset variables as errors and make pipelines fail if any command fails.
# No "set -e" on purpose: one failed backup must not skip the others.
set -uo pipefail

BACKUP_SCRIPT=/apps/deploy/.scripts/create-backup-borg.sh
failed=0

# run_backup <name> <borg-repository> <source-directory>
run_backup() {
    local name="$1" repo="$2" source="$3" rc

    echo "[$(date '+%F %T')] Starting backup: $name"
    "$BACKUP_SCRIPT" "$repo" "$source"
    rc=$?

    if [ "$rc" -eq 0 ]; then
        echo "[$(date '+%F %T')] Finished backup: $name"
    else
        echo "[$(date '+%F %T')] FAILED backup: $name (exit code $rc)" >&2
        failed=1
    fi
}

run_backup vaultwarden /apps/storage/backups/vaultwarden /apps/data/vaultwarden/
run_backup siyuan /apps/storage/backups/siyuan /apps/data/siyuan/
run_backup immich /apps/storage/backups/immich/ /apps/storage/media/immich/

exit "$failed"
