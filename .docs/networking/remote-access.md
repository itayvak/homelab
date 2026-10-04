# Remote access

When I'm not home, I connect to the homelab over SSH through [Tailscale](https://tailscale.com/). Tailscale creates a private network (a tailnet) between my devices, so SSH doesn't need to be exposed to the internet.

## How it works

The homelab runs the Tailscale client (`tailscaled`) and is a member of my tailnet, along with the offsite backup server:

| Hostname           | Tailscale IP    | Notes                                                        |
| ------------------ | --------------- | ------------------------------------------------------------- |
| `itayvak-homelab`  | `100.73.163.72` | The main homelab server.                                     |
| `itayvak-backlab`  | `100.127.121.5` | Offsite backup target, see [Backups](../backups/index.md#offsite-backups). |

From any other device on the tailnet (laptop, phone), SSH works the same as on the home network, using the Tailscale name or IP:

```bash
ssh <USER>@itayvak-homelab
```

This is regular OpenSSH on the server. Tailscale SSH is not enabled, so the normal SSH login is used.

## What it doesn't do

- **No router configuration is needed.** Tailscale connects outward, so there is no port forwarding for it, and port 22 is not forwarded, see [Router](router.md#port-forwarding).
- **It is separate from the web traffic.** The services are still reached through Cloudflare and Caddy, see [Networking](index.md). Tailscale is only for administering the server and for the offsite backup, see below.

## Offsite backups

The homelab also uses the tailnet to push nightly Borg backups to `itayvak-backlab` over SSH, the same way I SSH in to administer the server. See [Offsite backups](../backups/index.md#offsite-backups) for how that's set up.

## Managing devices

Devices are added and removed in the Tailscale admin console (https://login.tailscale.com/admin/machines). To check the connection from the server:

```bash
tailscale status
```

A device that is lost should be removed from the admin console so it can no longer reach the homelab.
