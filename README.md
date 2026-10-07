# Deploy and Host 9Router on Railway

9Router is a self-hosted AI gateway that puts a single OpenAI-compatible endpoint in front of 40+ model providers and 100+ models. You point Claude Code, Cursor, Cline, Copilot, Codex, OpenCode or any OpenAI-compatible client at one `/v1` URL, and manage providers, keys, fallback order and spend from one dashboard — instead of pasting a different API key into every tool.

[![Deploy on Railway](https://railway.app/button.svg)](https://github.com/ZedTheGreatt/9router-railway.git)

## About Hosting 9Router

Hosting 9Router means running a single Node.js service with a persistent disk. There is no Postgres and no Redis to operate — providers, issued API keys, fallback chains ("combos"), usage history and settings all live in an embedded SQLite database under `DATA_DIR`, alongside automatic backups. On Railway that maps to one service built from the official `decolua/9router` image, a volume mounted at `/app/data`, and a public HTTPS domain. The container listens on port `20128`, so `PORT` is pinned to `20128` rather than Railway's usual default. Because the dashboard and the `/v1` routes are exposed on the public internet, the security-relevant variables — dashboard password, JWT secret, API-key HMAC secret — are the part of the setup that actually needs your attention; everything else is pre-configured.

## Common Use Cases

- Giving a team one gateway URL for every AI coding tool, so provider keys live in one place instead of on each developer's laptop
- Riding out per-provider rate limits and quota exhaustion with automatic fallback chains, without editing any client config
- Attributing spend — seeing which model answered which request, at what cost, across providers

## Dependencies for 9Router Hosting

- **Persistent volume** — SQLite database, backups and logs at `/app/data`
- **Upstream provider accounts** — 9Router routes and meters calls, it does not resell tokens; you still pay each provider directly

### Deployment Dependencies

- [9Router GitHub Repository](https://github.com/decolua/9router)
- [9Router Docker Guide](https://github.com/decolua/9router/blob/master/DOCKER.md)
- [Railway Volumes Documentation](https://docs.railway.com/reference/volumes)

## Implementation Details

### Variables set in the template

`railway.toml` carries only `[build]` and `[deploy]` — Railway's config-as-code schema has no `[variables]` or `[[volumes]]` section, so these are defined in the template composer instead. Deployers do not need to touch them. (`HOSTNAME=0.0.0.0` and `NODE_ENV=production` are already baked into the upstream image, so they are not set at all.)

| Variable | Value | Why |
|---|---|---|
| `PORT` | `20128` | The image listens on `20128`; Railway must proxy to that exact port |
| `DATA_DIR` | `/app/data` | Matches the mounted volume; SQLite lands at `/app/data/db/data.sqlite` |
| `BASE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Resolves to your deployed domain for server-side jobs |
| `AUTH_COOKIE_SECURE` | `true` | Railway terminates TLS, so the auth cookie should be `Secure` |
| `REQUIRE_API_KEY` | `true` | Enforces a Bearer key on `/v1/*` — the endpoint is publicly reachable |
| `ENABLE_REQUEST_LOGS` | `false` | Request/response bodies stay off by default; flip to `true` to debug |

### Variables the deployer must set

| Variable | How to set it |
|---|---|
| `INITIAL_PASSWORD` | Your first dashboard login password. **The upstream default is `123456`** — set a real value before deploying |
| `JWT_SECRET` | `${{ secret(32) }}` — signs the dashboard session cookie |
| `API_KEY_SECRET` | `${{ secret(32) }}` — HMAC secret for the API keys you issue |
| `MACHINE_ID_SALT` | `${{ secret(32) }}` — salt for machine-ID hashing |

`JWT_SECRET` is optional upstream (9Router generates one into the volume if unset), but setting it explicitly keeps existing sessions valid across a volume reset or a second instance.

### Volume

One volume mounted at `/app/data`, matching `DATA_DIR`. Attached in the composer (right-click the service → **Attach Volume**).

### No healthcheck path

9Router documents no health endpoint and the image declares no `HEALTHCHECK`, so `railway.toml` deliberately omits `healthcheckPath` and lets Railway fall back to a TCP check on `PORT`. Adding a healthcheck against a route that does not exist would fail the deploy on an otherwise healthy service.

## After Deploying

1. Open `https://<your-domain>/dashboard` and log in with `INITIAL_PASSWORD`.
2. Add provider credentials under **Providers**, then build a fallback chain (Tier 1 → Tier 2 → Tier 3).
3. Issue an API key from the dashboard — `REQUIRE_API_KEY=true` means `/v1/*` rejects unauthenticated calls.
4. Point a client at the gateway:

   ```bash
   export ANTHROPIC_BASE_URL="https://<your-domain>"
   export ANTHROPIC_AUTH_TOKEN="<key from the dashboard>"
   ```

   Or for any OpenAI-compatible tool, use `https://<your-domain>/v1` as the base URL.

## Why Deploy 9Router on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you do not have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying 9Router on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.

## License

9Router is MIT licensed. This repository contains only the Railway deployment configuration.
