# Immich Backup Guide

## Database backup solution

Since Immich's database and media are separate components, we use two backup mechanisms: Immich's built-in database backup for the database, and Borg for the media files.

For the database, we use the built-in backup functionality in Immich.

It is configured through the Immich web interface to automatically create a database backup every day at 2:55 AM. The exact time is important because the Borg backup runs shortly after.

Immich stores these database backups in a directory inside the Immich media directory. This is somewhat unintuitive, but it is used for our backup strategy.

On the homelab, the directory for the database backups is `/apps/storage/media/immich/backups`.

## Media backup solution

For the media files, we use Borg.

A cron job in itayvak's crontab runs `/apps/deploy/.scripts/run-backup.sh` every day at 3:00 AM. That script runs `/apps/deploy/.scripts/create-backup-borg.sh` for each backed-up service, including Immich. The Borg script creates a new Borg archive and also handles pruning old archives and compacting the repository. See [Backups](index.md) for the details.

On the homelab, the Borg repository is located at `/apps/storage/backups/immich`.

Because the Immich database backup directory is located inside the media directory, Borg backs up the database backup alongside the media.

This means that each Borg archive contains both:

- The Immich media files as they existed at that point in time
- The database backup that was present in the media directory at that point in time

This allows us to restore a Borg archive and then restore the corresponding Immich database backup alongside the media.

## Backup synchronization

The two backup processes are intentionally scheduled five minutes apart: the database backup runs at 2:55 AM, and the media backup runs at 3:00 AM.

This ensures that the database backup created at 2:55 AM is included in the Borg archive created at 3:00 AM.

!!! warning "The database backup must finish first"
    The database backup must finish before the Borg job starts. If the database backup takes longer than five minutes, Borg could start before the new database backup has been created, resulting in the Borg archive containing the previous database backup instead.

For that reason, the database backup duration should be monitored if the Immich library becomes significantly larger.

Vaultwarden is backed up first in `run-backup.sh`, so the Immich archive starts a few seconds after 3:00 AM. That only gives the database backup slightly more time.

I don't particularly love this setup, as it can be a bit clunky, but it works well and I've tried many other solutions and couldn't find a better one.

## Restoring a backup

Restoring to a past backup requires extracting both the media and database backups.

!!! danger "This is a destructive action"
    All current data will be lost. Before doing anything else, create a fresh Borg archive as a restore point, and do not proceed until it completes successfully:

    ```bash
    /apps/deploy/.scripts/create-backup-borg.sh /apps/storage/backups/immich /apps/storage/media/immich/
    ```

### 1. Setup

Restoring must be done as **root**. Borg can only restore the original file owners when it runs as root, and Immich's containers need the original ownership to keep working.

```bash
sudo -i
```

Now, we need to stop the Immich deployment:

```bash
cd /apps/deploy/immich
docker compose down
```

Then, we move the current media directory out of the way to make room for the restored data. Moving it instead of deleting it means a wrong snapshot or a failed extract is not fatal. This needs enough free disk space to hold both copies, so check `df -h /apps/storage` first.

```bash
mv /apps/storage/media/immich /apps/storage/media/immich.old
```

### 2. Restore Borg snapshot

Now we can restore the directory using a Borg snapshot.

Export the Borg passphrase so you don't have to re-enter it every time:

```bash
export BORG_PASSCOMMAND='cat /apps/secrets/borg-passphrase'
```

This relies on the `/apps/secrets/borg-passphrase` file. The passphrase and the key are also stored in a note in my [Bitwarden](https://passwords.itayvak.com/).

Before restoring the backup, we must be in the `/` directory so that Borg restores the files to their original locations:

```bash
cd /
```

To restore a snapshot, we first need to find the name of the snapshot we want to restore. Run:

```bash
borg list /apps/storage/backups/immich
```

You will see something like this:

```text
backup-2026-09-18_03-00-01           Fri, 2026-09-18 03:00:01 [8de27e0082c0d8eb1251c11957d32c15e6569bedb13da0e7a2c926681bfa9318]
backup-2026-09-19_03-00-01           Sat, 2026-09-19 03:00:01 [592e36d38ca27713183404bad3d1d9a8bc09fed945643d88f6bc8c78139bd787]
<SNAPSHOT_NAME>                      <DATE>                   <ARCHIVE_ID>
```

Copy the snapshot name. Now we can extract it:

```bash
borg extract /apps/storage/backups/immich::<SNAPSHOT_NAME>
```

This will repopulate the `/apps/storage/media/immich` directory with the files from the selected snapshot.

The `/apps/storage/media/immich/backups` directory is also restored. Since the database backups are created at 2:55 AM, five minutes before the Borg snapshot, the corresponding database backup should also be present.

### 3. Restore database

After the previous step, we can start Immich so that we can restore the database using Immich's built-in backup tool.

Start Immich:

```bash
cd /apps/deploy/immich
docker compose up -d
```

Immich is now running with the restored media files. However, the database still contains the current data, so the database and media files are temporarily out of sync.

To synchronize them, we must restore the database backup using Immich's built-in backup tool.

Go to the **Maintenance** tab in the **Administration** settings and click **Restore** on the most recent database backup in the list. That is the one that was restored from the Borg snapshot, taken at 2:55 AM on the day of the snapshot.

Immich will now load the database backup. Do not perform any actions while the restore is in progress and wait for the page to reload automatically.

Once the page has reloaded, the database and media should be restored to the selected backup.

### 4. Clean up

Once you have checked that photos and albums look right, delete the old copy to free up space:

```bash
rm -rf /apps/storage/media/immich.old
```
