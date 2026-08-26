# Services

This page will outline the services that I offer with the homelab.

| Service Name | What It Is                                    | Subdomain                     | Has Backups |
| -------------- | ----------------------------------------------- | ------------------------------- | ------------- |
| Immich       | Photo service, Google Photos replacement      | https://photos.itayvak.com    | Yes         |
| Vaultwarden  | Private server for Bitwarden password manager | https://passwords.itayvak.com | Yes         |
| DroneCI      | CI platform                                   | https://ci.itayvak.com        | No          |
| Headscale    | Private server for Tailscale VPN              | https://vpn.itayvak.com       | No          |
| DDNS         | Auto DNS updater for Cloudflare               | None                          | No          |
| Planka       | Kanban project manager                        | https://boards.itayvak.com    | No          |
| Secret       | Secret                                        | https://secret.itayvak.com    | No          |
| Caddy        | Reverse proxy                                 | None                          | No          |
| SiYaun       | Note taking app, Notion replacement           | https://notes.itayvak.com     | Yes         |


# Filesystem

All of the files for the homelab services are saved at `/apps`. Inside it, these subdirecories exist:

- `/apps/deploy` - The deployment YAMLs for the services. All services are deployed using Docker Compose. This directory is also a Git repository for easier editing.

  - `/apps/deploy/.scripts` - Helper scripts for managing the services.
  - `/apps/deploy/<SERVICE_NAME>` - Every service has its own directory with everything it needs to deploy. Usually contains a docker-compose.yml, and a .env file.
- `/apps/secrets` - Secret values I want stored on the server.
- `/apps/data` - Data that the apps use. Unlike the storage directory, this is stored on the SSD, use this for smaller volume data that gets accessed rapidly, such as database data.

  - `/apps/data/<SERVICE_NAME>` - Every service has its own directory with its data.
- `/apps/storage` - Data that is mounted to the HDD. Use this for high volume data like media.

  - `/apps/storage/media/<SERVICE_NAME>` - Service data. Every service has its own directory with its data.
  - `/apps/storage/backups/<SERVICE_NAME>/borg` - Backups for services that use backups. I implement backups and versioning using Borg, read more about backups ((20260822180128-x0whhyy "here."))

---

Apps I want to deply in the future:

- Immich: auto stack duplicates
- Immich migrate photos from Google photos backup
- Container security (resources + premissions)
- Some kind of monitoring