# Domain

All services are served under subdomains of `itayvak.com`, and the domain's DNS is managed in Cloudflare.

My Cloudflare configuration only has one record, which is:

| Name            | Type | Content                      | Proxy status | TTL  |
| --------------- | ---- | ---------------------------- | ------------ | ---- |
| `*.itayvak.com` | A    | The home's public IP address | Proxied      | Auto |

The bare domain has no record. A wildcard only matches subdomains, so `itayvak.com` itself does not open anything. Only names like `photos.itayvak.com` work.

Because of the wildcard record, a new subdomain needs no DNS change. It only needs adding a route in the reverse proxy. See [how to add a new route here.](reverse-proxy.md#adding-a-new-service)

## DDNS

My ISP can and does change my home IP address from time to time, so I have a Dynamic DNS service running to automatically change the IP if needed.

It is configured to:

- Update the wildcard record (`*.itayvak.com`), so every subdomain points to the homelab.
- Use the Cloudflare proxy (`PROXIED=true`), so traffic goes through Cloudflare instead of straight to my IP.
- Authenticate to Cloudflare with an API key, which is stored in `/apps/deploy/ddns/.env`..

## Effects of the Cloudflare proxy

- My home IP address is not exposed in DNS.
- Cloudflare applies its own limits to traffic that goes through it. For example, it limits the size of uploads, which matters for Immich. See [Reverse proxy](reverse-proxy.md#immich).

## Cloudflare encryption mode

The SSL/TLS encryption mode is set to **Full**, in the Cloudflare dashboard under SSL/TLS. It decides how the connection between Cloudflare and the homelab is secured:

- Traffic is encrypted between the visitor and Cloudflare, and again between Cloudflare and Caddy.
- Cloudflare does not check Caddy's certificate in this mode, it accepts any certificate, including a self-signed one.
