# Reverse proxy

I use [Caddy](https://caddyserver.com/) as the reverse proxy. It is the only entry point from the internet: it receives all web traffic, handles HTTPS, and forwards each request to the right container based on the subdomain.

## How Caddy is deployed

Caddy is deployed from `/apps/deploy/caddy`:

| What                | Value                                                           |
| ------------------- | --------------------------------------------------------------- |
| Container           | `caddy`, from the `caddy:latest` image                          |
| Published ports     | `80` (TCP), `443` (TCP), `443` (UDP, for HTTP/3)                |
| Configuration       | `/apps/deploy/caddy/config/Caddyfile`, mounted at `/etc/caddy`  |
| Data                | `/apps/data/caddy`, mounted at `/data`                          |
| Docker network      | `homelab`                                                       |

The `/apps/data/caddy` directory holds the TLS certificates and their private keys, so it is only readable by root. It is not part of any backup, because Caddy gets new certificates automatically if it is lost.

## The `homelab` Docker network

Caddy reaches the other containers through the external Docker network `homelab`. Every service that Caddy serves joins this network, and Caddy connects to it by **container name** and the port the app listens on inside the container, for example `siyuan:6806`. The network is not tied to a compose project, so it is created once by hand:

```bash
docker network create homelab
```

Since the containers are only reachable through this network, they do not need to publish any ports on the host.

## Routes

These are the routes in the Caddyfile:

| Subdomain                | Container and port  | Notes                                |
| ------------------------ | ------------------- | ------------------------------------ |
| `photos.itayvak.com`     | `immich_server:2283` | See [Immich](#immich)                |
| `passwords.itayvak.com`  | `vaultwarden:80`    |                                      |
| `notes.itayvak.com`      | `siyuan:6806`       |                                      |
| `boards.itayvak.com`     | `planka:1337`       |                                      |
| `docs.itayvak.com`       | `mkdocs:80`         |                                      |
| `monitoring.itayvak.com` | `beszel:8090`       |                                      |
| `secret.itayvak.com`     | `youaregay:80`      | A joke website                       |

The Caddyfile also has a commented-out `testing.itayvak.com` block. Uncomment it and point it at a container to try a new app on a temporary address.

## HTTPS

Caddy handles HTTPS by itself. For every subdomain in the Caddyfile it requests a certificate from a public certificate authority, keeps it in `/apps/data/caddy`, and renews it before it expires. There is nothing to configure per service.

This only works if Caddy is reachable from the internet on ports 80 and 443, see [Router](router.md).

## Immich

Immich is reachable in two ways:

| Address                                              | Path                                             | Use                              |
| ---------------------------------------------------- | ------------------------------------------------ | -------------------------------- |
| `https://photos.itayvak.com`                         | Cloudflare, then Caddy                           | From anywhere                    |
| `http://<HOMELAB_LOCAL_ADDRESS>:2283`                | Directly to the `immich_server` container        | On the home network, large uploads |

Traffic through Cloudflare has an upload size limit that I can't change, so large photo and video uploads through the domain can fail. On the home network I use the direct address instead. Immich publishes port 2283 on the homelab for this, and it bypasses both Cloudflare and Caddy. That means no HTTPS on this address, so it is only for the local network and must not be forwarded on the router, see [Router](router.md).

The Caddyfile route for Immich is a plain reverse proxy, with no special upload settings. Settings such as a larger request size or longer timeouts would not help, because the limit is on Cloudflare's side, and traffic through the domain always passes through Cloudflare first.

## Adding a new service

1. Put the service's container on the `homelab` network in its compose file:

    ```yaml
    services:
      myapp:
        container_name: myapp
        networks:
          - homelab

    networks:
      homelab:
        external: true
    ```

2. Add a block to `/apps/deploy/caddy/config/Caddyfile`:

    ```text
    myapp.itayvak.com {
        reverse_proxy myapp:8080
    }
    ```

3. Check the file and reload Caddy without restarting it:

    ```bash
    docker exec caddy caddy validate --config /etc/caddy/Caddyfile
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile
    ```

4. Open the new address. The first request can take a few seconds while Caddy gets the certificate.
5. Add the service to the [Services](../services.md) table.

No DNS change is needed, because the wildcard record already covers every subdomain, see [Domain](domain.md#wildcard-record-and-ddns).

## Troubleshooting

- **502 Bad Gateway:** Caddy can't reach the container. Check that the container is running, that it is on the `homelab` network (`docker network inspect homelab`), and that the port in the Caddyfile is the port the app listens on inside the container.
- **Certificate errors on a new subdomain:** look at the Caddy logs with `docker logs caddy`. Caddy needs ports 80 and 443 reachable from the internet to get a certificate.
- **A change is not picked up:** validate and reload Caddy as shown above, or restart it with `docker compose restart` in `/apps/deploy/caddy`.
