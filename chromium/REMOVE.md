# Removing the remote browser

`browser.itayvak.com` (Chromium) and its login page `auth.itayvak.com` (TinyAuth) are a temporary setup for using WhatsApp Web from the work PC. This page lists everything that was added for it, and how to remove all of it.

## What was added

| What                                    | Where                                                                                    |
| --------------------------------------- | ---------------------------------------------------------------------------------------- |
| Containers `chromium`, `chromium_tinyauth` | `/apps/deploy/chromium/docker-compose.yaml`                                           |
| Secrets (container login, TinyAuth login and user hash) | `/apps/deploy/chromium/.env` (not in Git)                                 |
| Browser profile, WhatsApp login, downloads | `/apps/data/chromium`                                                                 |
| TinyAuth sessions database              | `/apps/data/tinyauth`                                                                    |
| Caddy routes for `browser.` and `auth.itayvak.com`, and the `(cloudflare_only)` snippet | `/apps/deploy/caddy/config/Caddyfile`, the section starting at `# ---- Remote Chromium` |
| Caddyfile backups made while setting this up | `/apps/deploy/caddy/config/Caddyfile.bak-*`                                         |
| Git ignore rule for those backups       | `/apps/deploy/.gitignore`                                                                |
| Documentation                           | `.docs/services.md`, `.docs/filesystem.md`, `.docs/networking/reverse-proxy.md`          |

Nothing was changed in DNS, Cloudflare or the router. The wildcard record already covers both subdomains, so there is nothing to undo there. If I added a Cloudflare rate limiting rule for `browser.itayvak.com`, delete it in the Cloudflare dashboard (Security > WAF > Rate limiting rules).

## Steps

0. **Selfie Timelapse uses this TinyAuth too.** `timelapse.itayvak.com` uses the `chromium_tinyauth` container and the `(cloudflare_only)` snippet. Before removing them, either remove Selfie Timelapse too (delete its `timelapse.itayvak.com` block in the Caddyfile and run `docker compose down` in `/apps/deploy/selfie-timelapse`), or move TinyAuth and the snippet somewhere else first. Otherwise the timelapse site is left without a login. If TinyAuth stays, also keep its `/apps/data/tinyauth` and the `TINYAUTH_APPS_TIMELAPSE_*` settings.


1. **Unlink WhatsApp first.** On the phone, go to WhatsApp > Settings > Linked devices, tap the Chromium (Linux) session and log out. Deleting the server data does not unlink it, it would stay linked until WhatsApp expires it.

2. **Stop and delete the containers and their images:**

    ```bash
    cd /apps/deploy/chromium
    docker compose down --rmi all
    ```

3. **Remove the Caddy routes.** In `/apps/deploy/caddy/config/Caddyfile`, delete everything from the line `# ---- Remote Chromium (WhatsApp Web from work)` down to the end of the `auth.itayvak.com { ... }` block (the `(cloudflare_only)` snippet, `browser.itayvak.com` and `auth.itayvak.com`). Then check and reload Caddy. This doesn't restart it, and the other sites keep working:

    ```bash
    docker exec caddy caddy validate --config /etc/caddy/Caddyfile
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile
    rm /apps/deploy/caddy/config/Caddyfile.bak-*
    ```

    Caddy deletes the two certificates by itself after they expire. Nothing needs to be done about them.

4. **Delete the data.** It contains the WhatsApp session and any downloaded files. The data directories need `sudo`, because `/apps/data` belongs to root:

    ```bash
    sudo rm -rf /apps/data/chromium /apps/data/tinyauth
    ```

5. **Delete this directory**, including `.env`:

    ```bash
    rm -rf /apps/deploy/chromium
    ```

6. **Clean up Git and the docs:**
    - `.gitignore`: delete the line `caddy/config/Caddyfile.bak-*`.
    - `.docs/services.md`: delete the Chromium row.
    - `.docs/filesystem.md`: delete the `/apps/data/chromium` and `/apps/data/tinyauth` rows.
    - `.docs/networking/reverse-proxy.md`: delete the `browser.itayvak.com` and `auth.itayvak.com` rows in the routes table, and the whole "Remote browser" section.

    Then commit.

7. **Check that it's gone:**

    ```bash
    docker ps -a | grep -i -e chromium -e tinyauth             # no output
    curl -s -o /dev/null -w '%{http_code}\n' https://browser.itayvak.com/   # no longer the login redirect
    ```

8. **On the work PC,** clear the `itayvak.com` cookies in Chrome. TinyAuth's session cookie is set on `.itayvak.com`, and it's useless once TinyAuth is gone, but there's no reason to keep it.
