# Itayvak Homelab

Welcome! This is the documentation for my homelab: a single Linux server that runs my self-hosted apps, from photos and passwords to notes and boards.

Everything runs in Docker containers, deployed with Docker Compose and exposed through the Caddy reverse proxy. The deployment files, scripts and these docs all live in one [Git repository](https://github.com/itayvak/homelab).

## Where to start

| I want to...                                   | Go to                                   |
| ---------------------------------------------- | --------------------------------------- |
| See what is running and at which address       | [Services](services.md)                 |
| Find where files and data live on the server   | [Filesystem](filesystem.md)             |
| Understand how traffic reaches the services    | [Networking](networking.md)             |
| Back up, verify or restore data                | [Backups](backups/backups.md)           |
| Restore the photo library                      | [Immich backups](backups/backups-immich.md) |

## The big picture

- **Services** are deployed from `/apps/deploy/<SERVICE_NAME>`, and store their data under `/apps/data` (SSD) or `/apps/storage` (HDD).
- **Caddy** receives all web traffic and forwards it to the right container by subdomain.
- **Borg** backs up the important data every night at 3:00 AM.
- **Beszel** monitors the server and its containers.

## Ideas for the future

- Immich: automatically stack duplicate photos
- Immich: migrate photos from a Google Photos backup
- Container security: resource limits and permissions
- Offsite backups
- Failure alerts for backups
