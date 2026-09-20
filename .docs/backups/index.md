# Backups

It is important to back up data that lives on the homelab, so that I won't hate myself when something eventually corrupts.

I use Borg as the backup system.

These are the repos I currently have:

| Service Name | Repository Directory                | Source Directory             | Notes                                                                    |
| ------------ | ----------------------------------- | ---------------------------- | ------------------------------------------------------------------------ |
| Immich       | `/apps/storage/backups/immich`      | `/apps/storage/media/immich` | This backup is a bit complicated.<br />See more [here](backups-immich.md) |
| Vaultwarden  | `/apps/storage/backups/vaultwarden` | `/apps/data/vaultwarden`     | See [known limitations](#known-limitations)                              |
| SiYuan       | `/apps/storage/backups/siyuan`      | `/apps/data/siyuan`          |                                                                          |

!!! warning "Backups are stored on the same machine as the data"
    All backups are stored on the HDD (`/apps/storage/backups`), on the same machine as the data. Services whose data is on the SSD (Vaultwarden, SiYuan) survive an SSD failure, but Immich's media is on the HDD too, so losing the HDD loses both the photos and their backup. Nothing survives a fire, a theft or losing the whole machine. I plan to add an offsite backup server.

## Schedule

A cron job in user `itayvak`'s crontab (`crontab -e`) runs `/apps/deploy/.scripts/run-backup.sh` every day at 3:00 AM.

The script runs the backups one after the other, so a slow backup never overlaps with the next one. The small backups (Vaultwarden and SiYuan) run first because they take seconds, and then Immich, which can take a long time. If one backup fails, the others still run, and the script exits with an error code.

## Running Borg as itayvak

The Borg repositories, the passphrase file and the backup scripts are all owned by `itayvak`, so Borg commands don't need `sudo`. To avoid entering the passphrase every time, export it first:

```bash
export BORG_PASSCOMMAND='cat /apps/secrets/borg-passphrase'
```

!!! note
    `export` only affects the current shell. If you run `sudo borg ...`, `sudo` drops the variable, so pass it on the command line instead: `sudo BORG_PASSCOMMAND='cat /apps/secrets/borg-passphrase' borg ...`. Though running `sudo borg` is not needed, since the borg repositories are owned by `itayvak`.

## Creating a repository

If you want to start backing up a new directory, you must create a Borg repository for it first.

Borg repositories on the homelab are generally saved at `/apps/storage/backups/<SERVICE_NAME>`.

You can create one using the Borg init command:

```bash
mkdir <REPO_DIR>
borg init --encryption=repokey-blake2 <REPO_DIR>
```

Then, you will be prompted to enter a passphrase. For consistency, enter the passphrase found at `/apps/secrets/borg-passphrase`. This will also generate a key for the repository.

!!! danger "Save the key and passphrase"
    We need both the key and the passphrase to access the data in the repository, so I save the keys to Borg repos in [my Bitwarden](https://passwords.itayvak.com). To view the key you can run:

    ```bash
    borg key export <REPO_DIR>
    ```

    And then copy it into a new note in Bitwarden.

    **To do:** my Bitwarden is served by Vaultwarden, which runs on this homelab and is one of the things backed up here. If the homelab is lost, I can't reach the passphrase needed to restore it. Keep an offline copy of the passphrase and keys somewhere that does not depend on the homelab.

After creating the repository, add it to `/apps/deploy/.scripts/run-backup.sh` and to the table above.

## Creating a backup archive

In order to create a new backup of a directory, I use a short Bash script that I wrote.

The script can be used like so:

```bash
/apps/deploy/.scripts/create-backup-borg.sh <REPO_DIR> <SOURCE_DIR>
```

The script creates a new Borg archive and also handles pruning old archives and compacting the repository, which is not required but is good practice to have.

Archives are named `backup-YYYY-MM-DD_HH-MM-SS`, for example `backup-2026-09-20_03-00-01`.

The retention policy for archives is:

- 7 daily archives
- 3 weekly archives
- 3 monthly archives

Prune keeps one archive per day, so a manual archive made on the same day as the 3 AM one replaces it once the prune runs.

The first run of Borg after the cache has been lost (or after switching users) is slow, because Borg has to read and hash every file. Later runs skip unchanged files and are much faster.

## Verifying backups

A backup that was never restored is not proven. Every so often:

- Check the repository for corruption. This can take a long time on large repos:

    ```bash
    borg check <REPO_DIR>
    ```

- Do a test restore into a temporary directory and look at the files:

    ```bash
    mkdir /tmp/restore-test && cd /tmp/restore-test
    borg extract <REPO_DIR>::<ARCHIVE_NAME> <PATH_INSIDE_ARCHIVE>
    ```

- Make sure the latest archive is recent and the 3 AM cron job did not fail:

    ```bash
    borg list --last 3 <REPO_DIR>
    ```

## Restoring a single file

You don't have to restore everything. To browse an archive like a normal directory, mount it:

```bash
mkdir /tmp/borg-mount
borg mount <REPO_DIR>::<ARCHIVE_NAME> /tmp/borg-mount
# copy what you need out of /tmp/borg-mount, then:
borg umount /tmp/borg-mount
```

## Restoring a backup

Restoring to a past backup requires extracting an archive.

!!! danger "This is a destructive action"
    Before doing anything else, create a fresh Borg archive of the current data. Do not proceed until the archive completes successfully.

### 1. Setup

Restoring must be done as **root**. Borg can only restore the original file owners when it runs as root. If you extract as `itayvak`, every file becomes owned by `itayvak`, and containers running as other users may not be able to write to their data.

```bash
sudo -i
```

Now, we need to stop the deployment of the service we want to restore:

```bash
cd /apps/deploy/<SERVICE_NAME>
docker compose down
```

Then, we move the current source directory out of the way to make room for the restored data. Moving it instead of deleting it means a wrong archive or a failed extract is not fatal. This needs enough free disk space to hold both copies.

```bash
mv <SOURCE_DIR> <SOURCE_DIR>.old
```

### 2. Restore Borg archive

Now we can restore the directory using a Borg archive.

Export the Borg passphrase so you don't have to re-enter it every time:

```bash
export BORG_PASSCOMMAND='cat /apps/secrets/borg-passphrase'
```

This relies on the `/apps/secrets/borg-passphrase` file. The passphrase and the key are also stored in a note in my [Bitwarden](https://passwords.itayvak.com/).

Before restoring the archive, we must be in the `/` directory so that Borg restores the files to their original locations:

```bash
cd /
```

To restore an archive, we first need to find the name of the archive we want to restore. Run:

```bash
borg list <REPO_DIR>
```

You will see something like this:

```text
backup-2026-09-18_03-00-01           Fri, 2026-09-18 03:00:01 [8de27e0082c0d8eb1251c11957d32c15e6569bedb13da0e7a2c926681bfa9318]
backup-2026-09-19_03-00-01           Sat, 2026-09-19 03:00:01 [592e36d38ca27713183404bad3d1d9a8bc09fed945643d88f6bc8c78139bd787]
<ARCHIVE_NAME>                       <DATE>                   <ARCHIVE_ID>
```

Copy the archive name. Now we can extract it:

```bash
borg extract <REPO_DIR>::<ARCHIVE_NAME>
```

This will repopulate the source directory with the files from the selected archive.

### 3. Start the service and clean up

Start the service again and check that it works:

```bash
cd /apps/deploy/<SERVICE_NAME>
docker compose up -d
```

Once you are sure everything is fine, delete the old copy to free up space:

```bash
rm -rf <SOURCE_DIR>.old
```

## Total loss of the homelab

If the whole machine is lost and the repositories are still available (for example from an offsite copy):

1. Install Borg on the new machine.
2. Get the passphrase from the offline copy (see the to-do above).
3. The keys are stored inside the repositories (`repokey-blake2`), so the passphrase is enough to open them. If a repository's key is damaged, restore it with `borg key import <REPO_DIR> <KEY_FILE>` using the key saved in Bitwarden.
4. Follow the restore steps above, starting from step 2.

## Known limitations

- **Vaultwarden is backed up while it is running.** Vaultwarden uses SQLite in WAL mode (`db.sqlite3`, `db.sqlite3-wal`, `db.sqlite3-shm`), and copying those files while the service writes to them can produce an inconsistent database. The safe way is to take a snapshot with `sqlite3 db.sqlite3 ".backup <FILE>"` before backing up, or to stop the container briefly. This is not done yet, and `sqlite3` is not installed on the homelab.
- **Failures are silent.** If a backup fails, nothing notifies me. Check `borg list --last 3 <REPO_DIR>` from time to time.
- **Offsite backup does not exist yet**, see the warning at the top.
