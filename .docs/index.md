# Itayvak Homelab

Welcome! This is the documentation for my homelab: a single Linux server that runs my self-hosted apps, from photos and passwords to notes and boards.

Everything runs in Docker containers, deployed with Docker Compose and exposed through the Caddy reverse proxy. The deployment files, scripts and these docs all live in one [Git repository](https://github.com/itayvak/homelab).

## Where to start

| I want to...                                   | Go to                                   |
| ---------------------------------------------- | --------------------------------------- |
| See what is running and at which address       | [Services](services.md)                 |
| Find where files and data live on the server   | [Filesystem](filesystem.md)             |
| Understand how traffic reaches the services    | [Networking](networking/index.md)  |
| Add a new service to the reverse proxy         | [Reverse proxy](networking/reverse-proxy.md) |
| Back up, verify or restore data                | [Backups](backups/index.md)           |
| Restore the photo library                      | [Immich backups](backups/backups-immich.md) |

## The big picture

- **Services** are deployed from `/apps/deploy/<SERVICE_NAME>`, and store their data under `/apps/data` (SSD) or `/apps/storage` (HDD).
- **Caddy** receives all web traffic and forwards it to the right container by subdomain.
- **Borg** backs up the important data every night at 3:00 AM.
- **Beszel** monitors the server and its containers.


## Editing these docs

The docs are written in Markdown in `/apps/deploy/.docs` and are turned into a website by MkDocs with the Material theme. The site is built into a Docker image, so the running site only changes when the image is rebuilt:

```bash
cd /apps/deploy/mkdocs
docker compose up -d --build
```

The build uses `mkdocs build --strict`, so a broken link or a bad reference fails the build instead of shipping a broken page. The navigation is set in `/apps/deploy/mkdocs/mkdocs.yml`, so a new page needs to be added there too.

## Ideas for the future

- Migrate photos from my Google Photos backup to Immich
- Container security: resource limits and permissions
- Offsite backups
- Failure alerts for backups
- HDD health monitoring
