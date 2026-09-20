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

| Path            | Disk                    | Use                                |
| --------------- | ----------------------- | ---------------------------------- |
| `/apps/deploy`  | SSD (NVMe, the root fs) | Compose files, scripts, docs       |
| `/apps/data`    | SSD (NVMe, the root fs) | Small, fast data such as databases |
| `/apps/secrets` | SSD (NVMe, the root fs) | Secrets                            |
| `/apps/storage` | HDD (ext4 mount)        | Media and backups                  |

`/apps/storage` is a separate mount, so it can be missing if the HDD did not mount at boot. Docker would then write into the empty mount point on the SSD instead of the HDD. Check that the disk is mounted before starting services after a reboot:

```bash
findmnt /apps/storage
```

Check free space with `df -h /apps/data /apps/storage`.

## Adding a new service

1. Create `/apps/deploy/<SERVICE_NAME>/docker-compose.yml`, and a `.env` (plus `.env.example`) if it needs secrets.
2. Create the data directory at `/apps/data/<SERVICE_NAME>` (small data) or `/apps/storage/media/<SERVICE_NAME>` (large data), and mount it in the compose file.
3. Add the service to the reverse proxy in `/apps/deploy/caddy/config/Caddyfile`, see [Reverse proxy](networking/reverse-proxy.md#adding-a-new-service).
4. If it holds data I care about, create a Borg repository and add it to `run-backup.sh`, see [Backups](backups/backups.md).
5. Add it to the [Services](services.md) table.
6. Commit and push the change.

## Deploy directory conventions

Every service in `/apps/deploy/<SERVICE_NAME>` follows these rules:

- **Data is stored outside the repository**, under `/apps/data` or `/apps/storage`, and mounted into the container with an absolute path. The deploy directory only holds configuration.
- **Secrets go in `.env`**, next to the compose file. All `.env` files are ignored by Git (see `.gitignore`), so they are never pushed. Commit a `.env.example` with the variable names and no real values, so it is clear what needs to be set up on a new machine.
- **Containers join the external `homelab` network**, so that Caddy can reach them by container name. Create it once with `docker network create homelab`. Services that serve no traffic, such as `ddns`, don't need it.
- **Docker works without `sudo`.** `itayvak` is in the `docker` group, so run `docker compose ...` directly (this is root-equivalent access, like `sudo`). The command is `docker compose`, there is no separate `docker-compose` program.
- The exception to the first rule is configuration that belongs to the deployment itself, such as `caddy/config/Caddyfile`.

## Ownership and permissions

`/apps/deploy`, `/apps/secrets` and the backups belong to `itayvak`, so they can be edited without `sudo`. Data that containers write to keeps the owner the container needs:

| Path                                  | Owner                 | Why                                                                          |
| ------------------------------------- | --------------------- | ---------------------------------------------------------------------------- |
| `/apps`, `/apps/deploy`, `/apps/secrets` | `itayvak`          | I edit these by hand, without `sudo`. `/apps/secrets/borg-passphrase` is mode `600`. |
| `/apps/storage/backups`               | `itayvak`             | Borg runs as `itayvak`, so it must be able to write here.                    |
| `/apps/data/siyuan`                   | `itayvak`             | The SiYuan container runs as UID 1000, which is `itayvak`.                   |
| `/apps/data/planka/app-data`          | `itayvak`             | The Planka container runs as UID 1000, so it needs to write uploads here.    |
| `/apps/deploy/immich-stack/logs`      | `itayvak`             | The Immich Stack container runs as UID 1000.                                 |
| `/apps/data/immich`                   | UID `999`, mode `700` | The Immich PostgreSQL container owns it. Don't change this.                  |
| `/apps/data/planka/db-data`           | UID `70`, mode `700`  | The Planka PostgreSQL container owns it. Don't change this.                  |
| `/apps/data/vaultwarden`, `/apps/data/beszel` | `itayvak`  | Written by containers that run as root, so the owner does not matter to them. I own them so I can read and edit them without `sudo`. |
| `/apps/data/caddy`                    | `root`                | Holds the TLS private keys (`caddy/` is mode `700`). Keep it root-only.      |
| `/apps/storage/media/immich`          | `root`                | Written by the Immich container, which runs as root. New files are root-owned, so changing the owner would not stay consistent. |

Everything is readable without `sudo` except the two PostgreSQL directories and `/apps/data/caddy/caddy` (mode `700`, it holds TLS keys). Use `sudo` to look inside them.

!!! warning "Be careful with `chown -R`"
    - **Never change the owner of the PostgreSQL directories** (`/apps/data/immich`, `/apps/data/planka/db-data`). PostgreSQL refuses to start when its data directory belongs to another user, and the service goes down.
    - **Changing the owner of `/apps/storage/media/immich` makes the next Immich backup re-read all of the photos**, because Borg treats a changed owner as a changed file. It takes a long time. The root-run Immich container also creates new files as root, so the owner does not stay consistent.
    - Only run `chown` on the paths listed above.

## Git

`/apps/deploy` is a Git repository. It contains the compose files, scripts and docs, and does not contain secrets or data. Since `.env` files are ignored, they need to be backed up separately if I want to be able to rebuild the server from scratch. The `.env` files are not part of any Borg backup today.
