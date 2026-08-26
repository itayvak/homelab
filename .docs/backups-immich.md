# Immich Backup Guide

# Database backup solution

Because Immich's database and media are separate components, we use two backup mechanisms: Immich's built-in database backup for the database, and Borg for the media files.

For the database, we use the built-in backup functionality in Immich.

It is configured through the Immich web interface to automatically create a database backup every day at 2:55 AM. The exact time is important because the Borg backup runs shortly after.

Immich stores these database backups in a directory inside the Immich media directory. This is somewhat unintuitive, but it is used for our backup strategy.

On the homelab, the directory for the database backups is `/apps/storage/media/immich/backups`.

# Media backup solution

For the media files, we use Borg.

A cron job runs `/apps/scripts/create-backup-borg.sh` every day at 3:00 AM. The script creates a new Borg archive and also handles pruning old archives and compacting the repository.

On the homelab, the Borg repository is located at `/apps/storage/backups/immich/borg`.

Because the Immich database backup directory is located inside the media directory, Borg backs up the database backup alongside the media.

This means that each Borg archive contains both:

- The Immich media files as they existed at that point in time
- The database backup that was present in the media directory at that point in time

This allows us to restore a Borg archive and then restore the corresponding Immich database backup alongside the media.

# Backup synchronization

The two backup processes are intentionally scheduled five minutes apart: the database backup runs at 2:55 AM, and the media backup runs at 3:00 AM.

This ensures that the database backup created at 2:55 AM is included in the Borg archive created at 3:00 AM.

> [!IMPORTANT]
> The database backup must finish before the Borg job starts. If the database backup takes longer than five minutes, Borg could start before the new database backup has been created, resulting in the Borg archive containing the previous database backup instead.

For that reason, the database backup duration should be monitored if the Immich library becomes significantly larger.

I don't particularly love this setup, as it can be a bit clunky, but it works well and I've tried many other solutions and couldn't find a better one.

# Restoring a backup

Restoring to a past backup requires extracting both the media and database backups.

This is a highly destructive action. All current data will be lost. It is strongly recommended to create a backup as a restore point before restoring a past one.

## 1. Setup

First, make sure you are connected to the homelab as the root user. If not, run:

```bash
sudo su
```

Now, we need to stop the Immich deployment:

```bash
cd /apps/deploy/Immich
docker-compose down
```

Then, we delete the current media directory to make room for the restored data.

> [!CAUTION]
> This is highly destructive. Proceed with caution and make absolutely sure you are deleting the correct directory.

```bash
rm -rf /apps/storage/media/immich
```

## 2. Restore Borg snapshot

Now we can restore the directories we just deleted using the Borg snapshots.

Optional: For easier use, you can export the Borg passphrase so you don't have to re-enter it every time:

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
borg list /apps/storage/backups/immich/borg
```

You will see something like this:

```text
backup-21-08-2026_14-07-30           Fri, 2026-08-21 14:07:31 [34a8110e69a9ba14843cac204cc07837e0f3b62d58fd9564876af3e9550cd637]
backup-21-08-2026_14-28-20           Fri, 2026-08-21 14:28:20 [5e008193d54295057d51ad87c906437723e798d7651a1483c2505503ae354a19]
<SNAPSHOT_NAME>                      <DATE>                  <UUID>
```

Copy the snapshot name. Now we can extract it:

```bash
borg extract /apps/storage/backups/immich/borg::<SNAPSHOT_NAME>
```

This will repopulate the `/apps/storage/media/immich` directory with the files from the selected snapshot.

The `/apps/storage/media/immich/backups` directory is also restored. Since the database backups are created at 2:55 AM, five minutes before the Borg snapshot, the corresponding database backup should also be present.

## 3. Restore database

After the previous step, we can start Immich so that we can restore the database using Immich's built-in backup tool.

Start Immich:

```bash
cd /apps/deploy/Immich
docker-compose up -d
```

Immich is now running with the restored media files. However, the database still contains the current data, so the database and media files are temporarily out of sync.

To synchronize them, we must restore the database backup using Immich's built-in backup tool.

Go to the **Maintenance** tab in the **Administration** settings and click **Restore** on the latest backup:


Immich will now load the database backup. Do not perform any actions while the restore is in progress and wait for the page to reload automatically.

Once the page has reloaded, the database and media should be restored to the selected backup.