# Filesystem

All of the files for the homelab services are saved at `/apps`. Inside it, these subdirecories exist:

- `/apps/deploy` - The deployment YAMLs for the services. All services are deployed using Docker Compose. This directory is also a [Git repository](https://github.com/itayvak/homelab) for easier editing.

  - `/apps/deploy/.scripts` - Helper scripts for managing the services.
  - `/apps/deploy/<SERVICE_NAME>` - Every service has its own directory with everything it needs to deploy. Usually contains a docker-compose.yml, and a .env file.
- `/apps/secrets` - Secret values I want stored on the server.
- `/apps/.docs` - Documentation Markdown fies for all things homelab (The ones you're viewing right now). The MD files later get hosted onto a website using MKDocs.
- `/apps/data` - Data that the apps use. Unlike the storage directory, this is stored on the SSD, use this for smaller volume data that gets accessed rapidly, such as database data.
  - `/apps/data/<SERVICE_NAME>` - Every service has its own directory with its data.
- `/apps/storage` - Data that is mounted to the HDD. Use this for high volume data like media.
  - `/apps/storage/media/<SERVICE_NAME>` - Service data. Every service has its own directory with its data.
  - `/apps/storage/backups/<SERVICE_NAME>/borg` - Backups for services that use backups. I implement backups and versioning using Borg, read more about backups [here](backups/backups-immich.md).
