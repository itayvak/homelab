# Router

The home router exposes the required ports, and sends web traffic to the homelab so that Caddy can receive it.

To configure the router, access http://192.168.1.1/ on a device in the home LAN and log into the admin account (credentials stored in Vaultwarden). The configurations that were set up are described here:

## Port forwarding

To be able to access the router from the internet, these ports are published via port forwarding:

| Port | Protocol | Used for                                       |
| ---- | -------- | ---------------------------------------------- |
| 80   | TCP      | HTTP, and the certificate checks Caddy does    |
| 443  | TCP      | HTTPS                                          |
| 443  | UDP      | HTTP/3                                         |

These are the ports Caddy publishes, see [Reverse proxy](reverse-proxy.md#how-caddy-is-deployed).

!!! warning "Don't forward other ports"
    Immich also publishes port 2283 directly on the homelab, without HTTPS. This is on purpose, so that large uploads on the home network can bypass Cloudflare, see [Reverse proxy](reverse-proxy.md#immich). It is only meant for the local network, so don't forward it on the router. Everything from outside goes through Caddy.

## Fixed address

The homelab has a reserved local IP address, so that DHCP doesn't change its address every so often:

| Hostname          | IP address      | MAC Address         |
| ----------------- | --------------- | ------------------- |
| `itayvak-homelab` | `192.168.1.221` | `50:9a:4c:2b:2a:90` |

Things that depend on this address:

- The [port forwarding](#port-forwarding) rules send traffic to it, so they stop working if the address changes.
- The direct Immich address on the home network, `http://192.168.1.221:2283`, see [Reverse proxy](reverse-proxy.md#immich).

!!! note
    If the network card or the whole machine is replaced, the MAC address changes, and the lease has to be updated with the new one. Otherwise the homelab gets a different address and the port forwarding breaks.