# Networking

This section describes how traffic gets from the internet to the services on the homelab.

## How a request travels

```text
Browser
  │  https://photos.itayvak.com
  ▼
Cloudflare        DNS and proxy for the domain
  │
  ▼
Router            forwards ports 80 and 443 to the homelab
  │
  ▼
Caddy             reverse proxy, handles HTTPS and picks the service by subdomain
  │  Docker network "homelab"
  ▼
Service container (for example immich_server:2283)
```

Each step has its own page:

| Page                              | What it covers                                                   |
| --------------------------------- | ---------------------------------------------------------------- |
| [Domain](domain.md)               | The domain, Cloudflare DNS and the DDNS container                |
| [Router](router.md)               | The port forwarding the router needs                             |
| [Reverse proxy](reverse-proxy.md) | Caddy: routes, HTTPS, and how to add a new service               |

The list of services and their addresses is in [Services](../services.md).
