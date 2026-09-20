# Filesystem

All of the files for the homelab services are saved at `/apps`. Inside it, these subdirectories exist:

- `/apps/deploy` - The deployment YAMLs for the services. All services are deployed using Docker Compose. This directory is also a [Git repository](https://github.com/itayvak/homelab) for easier editing.
    - `/apps/deploy/.scripts` - Helper scripts, such as the [backup scripts](backups/backups.md).
    - `/apps/deploy/.docs` - Documentation Markdown files for all things homelab (the ones you're viewing right now). They get built into a website using MkDocs, see [Editing these docs](#editing-these-docs).
    - `/apps/deploy/<SERVICE_NAME>` - Every service has its own directory with everything it needs to deploy. Usually contains a `docker-compose.yml` (or `.yaml`), and a `.env` file.
- `/apps/secrets` - Secret values I want stored on the server, such as the Borg passphrase.
- `/apps/data` - Data that the apps use. Unlike the storage directory, this is stored on the SSD. Use it for smaller volume data that gets accessed rapidly, such as database data.
    - `/apps/data/<SERVICE_NAME>` - Every service has its own directory with its data.
- `/apps/storage` - Data that is mounted to the HDD. Use this for high volume data like media.
    - `/apps/storage/media/<SERVICE_NAME>` - Service data. Every service has its own directory with its data.
    - `/apps/storage/backups/<SERVICE_NAME>` - The Borg repository of a service that is backed up. There is no extra `borg` directory, the repository is the service directory itself. I implement backups and versioning using Borg, read more about backups [here](backups/backups.md).

## Disks

There are two physical disks, and `/apps` spans both of them:

| Path                | Disk                    | Size   | Use                                     |
| ------------------- | ----------------------- | ------ | --------------------------------------- |
| `/apps/deploy`      | SSD (NVMe, the root fs) | 233 GB | Compose files, scripts, docs            |
| `/apps/data`        | SSD (NVMe, the root fs) | 233 GB | Small, fast data such as databases      |
| `/apps/secrets`     | SSD (NVMe, the root fs) | 233 GB | Secrets                                 |
| `/apps/storage`     | HDD (`/dev/sda1`, ext4) | 2.7 TB | Media and backups                       |

`/apps/storage` is a separate mount, so it can be missing if the HDD did not mount at boot. Docker would then write into the empty mount point on the SSD instead of the HDD. Check that the disk is mounted before starting services after a reboot:

```bash
findmnt /apps/storage
```

Check free space with `df -h /apps/data /apps/storage`.

## Which disk holds what

Where a service keeps its data decides how well it survives a disk failure.

| Service     | Data                                    | Disk | Backup repository                   | Backup disk |
| ----------- | --------------------------------------- | ---- | ----------------------------------- | ----------- |
| Immich      | `/apps/storage/media/immich` (media)    | HDD  | `/apps/storage/backups/immich`      | HDD         |
| Immich      | `/apps/data/immich` (PostgreSQL)        | SSD  | Immich's database backups, inside the media directory | HDD |
| Vaultwarden | `/apps/data/vaultwarden`                | SSD  | `/apps/storage/backups/vaultwarden` | HDD         |
| SiYuan      | `/apps/data/siyuan`                     | SSD  | `/apps/storage/backups/siyuan`      | HDD         |
| Planka      | `/apps/data/planka`                     | SSD  | None                                | -           |
| Beszel      | `/apps/data/beszel`                     | SSD  | None                                | -           |

The SSD data is backed up to the HDD, so losing the SSD does not lose the data. Immich's media and its backups are both on the HDD, so losing the HDD loses both. See [Backups](backups/backups.md).

## Ownership and permissions

Most of `/apps` is owned by `root`, because it was created with `sudo`. Some paths are owned by other users on purpose:

| Path                         | Owner                | Why                                                        |
| ---------------------------- | -------------------- | ---------------------------------------------------------- |
| `/apps/deploy/.docs`, `.scripts`, `mkdocs/mkdocs.yml` | `itayvak` | I edit these by hand, without `sudo`.       |
| `/apps/secrets/borg-passphrase` | `itayvak`, mode `600` | Borg runs as `itayvak`, and so does the cron job.       |
| `/apps/storage/backups`      | `itayvak`            | Borg runs as `itayvak`, so it must be able to write here.  |
| `/apps/data/immich`          | UID `999`, mode `700` | The PostgreSQL container owns it. Don't change this, use `sudo` to look inside. |
| `/apps/data/siyuan`          | `itayvak`            | Created as `itayvak`. The SiYuan compose file does not set a container user. |

!!! warning "Be careful with `chown -R`"
    Several containers write into their data directories as a specific user. Changing the owner of `/apps/data` or `/apps/storage/media` recursively can stop those services from starting. Only run `chown` on the paths listed above.

## Deploy directory conventions

Every service in `/apps/deploy/<SERVICE_NAME>` follows these rules:

- **Data is stored outside the repository**, under `/apps/data` or `/apps/storage`, and mounted into the container with an absolute path. The deploy directory only holds configuration.
- **Secrets go in `.env`**, next to the compose file. All `.env` files are ignored by Git (see `.gitignore`), so they are never pushed. Commit a `.env.example` with the variable names and no real values, so it is clear what needs to be set up on a new machine.
- **Containers join the external `homelab` network**, so that Caddy can reach them by container name. Create it once with `docker network create homelab`. Services that serve no traffic, such as `ddns`, don't need it.
- **Docker needs `sudo`.** `itayvak` is not in the `docker` group, so run `sudo docker compose ...`. The command is `docker compose`, there is no separate `docker-compose` program.
- The exception to the first rule is configuration that belongs to the deployment itself, such as `caddy/config/Caddyfile`.

## Adding a new service

1. Create `/apps/deploy/<SERVICE_NAME>/docker-compose.yml`, and a `.env` (plus `.env.example`) if it needs secrets.
2. Create the data directory at `/apps/data/<SERVICE_NAME>` (small data) or `/apps/storage/media/<SERVICE_NAME>` (large data), and mount it in the compose file.
3. Add the service to the reverse proxy in `/apps/deploy/caddy/config/Caddyfile`.
4. If it holds data I care about, create a Borg repository and add it to `run-backup.sh`, see [Backups](backups/backups.md).
5. Add it to the [Services](services.md) table.
6. Commit and push the change.

## Editing these docs

The docs are written in Markdown in `/apps/deploy/.docs` and are turned into a website by MkDocs with the Material theme. The site is built into a Docker image, so the running site only changes when the image is rebuilt:

```bash
cd /apps/deploy/mkdocs
sudo docker compose up -d --build
```

The build uses `mkdocs build --strict`, so a broken link or a bad reference fails the build instead of shipping a broken page. The navigation is set in `/apps/deploy/mkdocs/mkdocs.yml`, so a new page needs to be added there too.

## Git

`/apps/deploy` is a Git repository. It contains the compose files, scripts and docs, and does not contain secrets or data. Since `.env` files are ignored, they need to be backed up separately if I want to be able to rebuild the server from scratch. The `.env` files are not part of any Borg backup today.
