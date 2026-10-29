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
| `albums.itayvak.com`     | `album-player:80`   | Static Spotify album picker page     |
| `browser.itayvak.com`    | `chromium:3000`     | See [Remote browser](#remote-browser) |
| `auth.itayvak.com`       | `chromium_tinyauth:3000` | Login page for the remote browser and Selfie Timelapse |
| `timelapse.itayvak.com`  | `selfie-timelapse:5000` | See [Selfie Timelapse](#selfie-timelapse) |

The Caddyfile also has a commented-out `testing.itayvak.com` block. Uncomment it and point it at a container to try a new app on a temporary address.

## HTTPS

Caddy handles HTTPS by itself. For every subdomain in the Caddyfile it requests a certificate from a public certificate authority, keeps it in `/apps/data/caddy`, and renews it before it expires. There is nothing to configure per service.

This only works if Caddy is reachable from the internet on ports 80 and 443, see [Router](router.md).

## Immich

Immich is reachable in two ways:

| Address                                              | Path                                             | Use                              |
| ---------------------------------------------------- | ------------------------------------------------ | -------------------------------- |
| `https://photos.itayvak.com`                         | Cloudflare, then Caddy                           | From anywhere                    |
| `http://192.168.1.221:2283`                          | Directly to the `immich_server` container        | On the home network, large uploads |

Traffic through Cloudflare has an upload size limit that I can't change, so large photo and video uploads through the domain can fail. On the home network I use the direct address instead. Immich publishes port 2283 on the homelab for this, and it bypasses both Cloudflare and Caddy. That means no HTTPS on this address, so it is only for the local network and must not be forwarded on the router, see [Router](router.md).

The Caddyfile route for Immich is a plain reverse proxy, with no special upload settings. Settings such as a larger request size or longer timeouts would not help, because the limit is on Cloudflare's side, and traffic through the domain always passes through Cloudflare first.

## Remote browser

`browser.itayvak.com` streams a Chromium browser running on the homelab (`/apps/deploy/chromium`, the `lscr.io/linuxserver/chromium` image). I use it for WhatsApp Web from my work PC, whose network blocks WhatsApp and where I can't install software. It holds a logged-in WhatsApp session, so its route is locked down more than the others. This is a temporary setup, [`chromium/REMOVE.md`](https://github.com/itayvak/homelab/blob/main/chromium/REMOVE.md) lists how to remove all of it.

- **Login page (TinyAuth).** The work PC's Chrome doesn't show basic auth prompts, so the login is a web page instead: [TinyAuth](https://github.com/tinyauthapp/tinyauth) at `auth.itayvak.com`, running as the `chromium_tinyauth` container in the same compose file. Caddy asks it about every request to `browser.itayvak.com` (`forward_auth`), and sends visitors who aren't logged in to the login page. The login is in `/apps/deploy/chromium/.env`. A session lasts 12 hours. 3 wrong passwords lock the username for 5 minutes.
- **The container's own login stays on.** I never type it: after login, TinyAuth gives Caddy the container's username and password (`CUSTOM_USER`/`PASSWORD` in `.env`), and Caddy adds them to the request. Other containers on the `homelab` network still can't open the browser without them.
- **Only listed domains are allowed.** TinyAuth denies every domain except the ones in its `TINYAUTH_APPS_*` settings: `browser.itayvak.com` and `timelapse.itayvak.com`.
- **Cloudflare only.** Requests that don't come from [Cloudflare's IP ranges](https://www.cloudflare.com/ips/) are dropped, on both subdomains, so nobody can reach them by connecting to the home IP directly. The ranges are in the `(cloudflare_only)` snippet in the Caddyfile. If Cloudflare changes them, the sites stop loading, and the list needs updating.
- **Everything is inside `route { }`,** so the Cloudflare check runs before anything else. Caddy's default order would run some handlers before `abort`.
- **Security headers:** HSTS, `X-Frame-Options DENY`, `nosniff`, `no-referrer`.

TinyAuth's session cookie is set on `.itayvak.com`, so the browser also sends it to the other subdomains. It only grants access to the domains listed in its settings (`browser.` and `timelapse.itayvak.com`).

The remote desktop stream is a WebSocket at `/api/websockets`. Caddy and Cloudflare both pass WebSockets through without extra settings.

To change the TinyAuth password, create a new hash and put it in `TINYAUTH_USERS` in `.env` (in single quotes), then recreate the container:

```bash
docker run --rm ghcr.io/tinyauthapp/tinyauth:latest user create --username itayvak --password '<NEW_PASSWORD>'
cd /apps/deploy/chromium && docker compose up -d
```

**Moving files between the PC and the remote browser** goes through the file section of the sidebar, on the left edge of the page. It works on `/apps/data/chromium/Downloads` (`FILE_MANAGER_PATH` in the compose file), which is also where Chromium saves downloads:

- **Server to PC:** download the file in the remote browser, then click it in the sidebar's file list, and it downloads to the PC.
- **PC to server:** upload it in the sidebar. It lands in `Downloads`, where the remote browser's file picker (for example, WhatsApp's attach button) can pick it.

Files stay in `Downloads` until deleted, either from the sidebar or with `rm` on the server. The browser profile (including the WhatsApp login) is in `/apps/data/chromium` and is not backed up. If it is lost, I scan the QR code again.

## Selfie Timelapse

`timelapse.itayvak.com` is [Immich Selfie Timelapse](https://github.com/ArnaudCrl/immich-automated-selfie-timelapse) (`/apps/deploy/selfie-timelapse`). It makes timelapse videos of a person from their Immich photos. The app has no login of its own and shows faces from the whole photo library, so it uses the same protection as the [remote browser](#remote-browser):

- **TinyAuth login** at `auth.itayvak.com`. One login covers both sites, because the session cookie is shared. The domain is allowed with the `TINYAUTH_APPS_TIMELAPSE_*` settings in `chromium/docker-compose.yaml`.
- **Cloudflare only**, with the same `(cloudflare_only)` snippet and `route { }` block.

The container publishes no port. It talks to Immich directly at `immich_server:2283` on the `homelab` network, with an Immich API key in `/apps/deploy/selfie-timelapse/.env`. Its settings are in `/apps/data/selfie-timelapse`, and the generated photos and videos are in `/apps/storage/media/selfie-timelapse`. Neither is backed up, since everything can be generated again.

It's a one-off tool, so I can stop it with `docker compose down` when I'm not using it. The route then shows a 502 after login.

!!! warning
    TinyAuth lives in the `chromium/` folder. Removing the remote browser with `chromium/REMOVE.md` would also remove this login, see the note there.

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
