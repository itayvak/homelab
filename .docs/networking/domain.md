# Domain

All services are served under subdomains of `itayvak.com`, and the domain's DNS is managed in Cloudflare.

## Wildcard record and DDNS

My home IP address can change, so a container called `ddns` keeps the DNS record up to date. It runs the `oznu/cloudflare-ddns` image, and is deployed from `/apps/deploy/ddns`.

It is configured to:

- Update a **wildcard record** (`*.itayvak.com`), so every subdomain points to the homelab.
- Use the Cloudflare **proxy** (`PROXIED=true`), so traffic goes through Cloudflare instead of straight to my IP.
- Authenticate to Cloudflare with an API key, which is stored in `/apps/deploy/ddns/.env` (not in Git).

Because of the wildcard record, **a new subdomain needs no DNS change**. It only needs a route in the reverse proxy, see [Reverse proxy](reverse-proxy.md#adding-a-new-service).

## Effects of the Cloudflare proxy

- My home IP address is not exposed in DNS.
- Cloudflare applies its own limits to traffic that goes through it. For example, it limits the size of uploads, which matters for Immich. See [Reverse proxy](reverse-proxy.md#immich).

!!! note "To do"
    Document the rest of the Cloudflare setup: the SSL/TLS mode, and any other DNS records or rules.
