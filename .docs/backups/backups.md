# Backups

It is important to back up data that lives on the homelab, so that I won't hate myself when something eventually corrupts.

I use Borg as the backup system.

These are the repos I currently have:

| Service Name | Repository Directory | Source Directory | Notes                                        |
| -------------- | ---------------------- | ------------------ | ---------------------------------------------- |
| Immich       | `/apps/storage/backups/immich/borg`                     | `/apps/storage/media/immich`                 | This backup is a bit complicated.<br />See more ((20260822175551-n3b5tik "here")) |
| Vaultwarden  | `/apps/storage/backups/vaultwarden/borg`                     | `/apps/data/vaultwarden`                 |                                              |

The backups currently get stored on the same drive as the data, which is not usefull for disaster recovery, but I plan to add an offsite backup server.


# Creating a repository

If you want to start backing up a new directory, you must create a Borg repository for it first.

Borg repositories on the homelab are generally saved at `/apps/storage/backups/<SERVICE_NAME>/borg`.

You can create one using the Borg init command:

```bash
mkdir <REPO_DIR>
borg init --encryption=repokey-blake2 <REPO_DIR>
```

Then, you will be prompted to enter a passphrase. For consistency, enter the passphrase found at `/apps/secrets/borg-passphrase`. This will also generate a key for the repository.

> [!IMPORTANT]
> We need both key and passphrase to access the data in the repository - so I save the keys to Borg repos in [my Bitwarden](https://passwords.itayvak.com). To view the key you can run:
>
> ```bash
> borg key export <REPO_DIR>
> ```
>
> And then copy it into a new note in Bitwarden.


# Creating a backup archive

In order to create a new backup of a directory, I use a short Bash script that I wrote.

The script can be used like so:

```bash
/apps/deploy/.scripts/create-backup-borg.sh <REPO_DIR> <SOURCE_DIR>
```

The script creates a new Borg archive and also handles pruning old archives and compacting the repository, which is not required but is good practice to have.

The retention policy for archives is:

- 7 daily archives
- 3 weekly archives
- 3 monthly archives


# Restoring a backup

Restoring to a past backup requires extracting an archive.

This is a highly destructive action. Before doing anything destructive, create a fresh Borg archive of the current data. Do not proceed until the archive completes successfully.

## 1. Setup

First, make sure you are connected to the homelab as the root user. If not, run:

```bash
sudo su
```

Now, we need to stop the deployment of the service we want to restore:

```bash
cd /apps/deploy/<SERVICE_NAME>
docker-compose down
```

Then, we delete the current source directory to make room for the restored data.

> [!CAUTION]
> This is highly destructive. Proceed with caution and make absolutely sure you are deleting the correct directory.

```bash
rm -rf <SOURCE_DIR>
```

## 2. Restore Borg archive

Now we can restore the directories we just deleted using a Borg archive.

*Optional: For easier use, you can export the Borg passphrase so you don't have to re-enter it every time:*

```bash
export BORG_PASSCOMMAND='cat /apps/secrets/borg-passphrase'
```

*This relies on the*  *`/apps/secrets/borg-passphrase`* *file. The passphrase and the key are also stored in a note in my* *[Bitwarden](https://passwords.itayvak.com/)* *.*

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
backup-21-08-2026_14-07-30           Fri, 2026-08-21 14:07:31 [34a8110e69a9ba14843cac204cc07837e0f3b62d58fd9564876af3e9550cd637]
backup-21-08-2026_14-28-20           Fri, 2026-08-21 14:28:20 [5e008193d54295057d51ad87c906437723e798d7651a1483c2505503ae354a19]
<ARCHIVE_NAME>                      <DATE>                  <UUID>
```

Copy the archive name. Now we can extract it:

```bash
borg extract <REPO_DIR>::<ARCHIVE_NAME>
```

This will repopulate the source directory with the files from the selected archive. Enjoy!