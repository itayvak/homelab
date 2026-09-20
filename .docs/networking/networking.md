# Networking

This section describes how traffic gets from the internet to the services on the homelab.

## How a request travels

```mermaid
flowchart TB
    browser["Browser<br/>https://photos.itayvak.com"]
    cf["Cloudflare<br/>DNS and proxy for the domain"]

    subgraph home["Home LAN<div style='width:400px'>"]
        router["Home router<br/>forwards ports 80 and 443"]

        subgraph lab["Homelab<div style='width:400px'>"]
            caddy["Caddy<br/>handles HTTPS, picks the service by subdomain"]
            immich["immich_server:2283"]
            vault["vaultwarden:80"]
            siyuan["siyuan:6806"]
            more["other services"]
        end
    end

    browser -->|HTTPS| cf
    cf -->|HTTPS| router
    router --> caddy
    caddy --> immich
    caddy --> vault
    caddy --> siyuan
    caddy --> more
```

Caddy and the service containers are connected by the Docker network `homelab`, which is how Caddy reaches a container by its name.

Each step has its own page:

| Page                              | What it covers                                                   |
| --------------------------------- | ---------------------------------------------------------------- |
| [Domain](domain.md)               | The domain, Cloudflare DNS and the DDNS container                |
| [Router](router.md)               | The port forwarding the router needs                             |
| [Reverse proxy](reverse-proxy.md) | Caddy: routes, HTTPS, and how to add a new service               |
