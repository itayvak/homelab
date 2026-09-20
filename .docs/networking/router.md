# Router

The router needs to send web traffic to the homelab so that Caddy can receive it.

## Port forwarding

Forward these ports to the homelab:

| Port | Protocol | Used for                                       |
| ---- | -------- | ---------------------------------------------- |
| 80   | TCP      | HTTP, and the certificate checks Caddy does    |
| 443  | TCP      | HTTPS                                          |
| 443  | UDP      | HTTP/3                                         |

These are the ports Caddy publishes, see [Reverse proxy](reverse-proxy.md#how-caddy-is-deployed).

!!! warning "Don't forward other ports"
    Immich also publishes port 2283 directly on the homelab, without HTTPS. This is on purpose, so that large uploads on the home network can bypass Cloudflare, see [Reverse proxy](reverse-proxy.md#immich). It is only meant for the local network, so don't forward it on the router. Everything from outside goes through Caddy.

## Fixed address

The homelab has a reserved address in the router's DHCP settings, so its local address does not change and the port forwarding keeps working.

!!! note "To do"
    Document the router model and where these settings are in its admin page.
