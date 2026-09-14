# Run Backstage with Docker

[Back to README](../README.md)

## Local development

You need Docker, Compose **2.30+**, your `app-config.local.yaml`, and the
`platform-blueprints` repository cloned alongside this repository.

From the repository root:

```sh
# First-time setup only; keep your existing .env.yarn if you already have one.
cp .env.example .env.yarn
```

Replace the placeholder credentials in `.env.yarn`, then start:

```sh
docker compose up --build
```

Open **<http://localhost:3000>**. The backend runs on port **7007**.

Compose reads `.env.yarn` for secrets and `app-config.local.yaml` for app settings.
It starts PostgreSQL automatically, uses separate dependency volumes, and mounts
`../platform-blueprints` read-only for your local templates. Source edits reload
automatically. Secrets stay out of the image.

Set your GitHub OAuth callback to
`http://localhost:7007/api/auth/github/handler/frame`. Your GitHub username must
match a User entity in `catalog/entities/users.yaml`.

```sh
docker compose logs -f backstage                       # View app logs
docker compose restart backstage                      # After dependency changes
docker compose up -d --force-recreate backstage        # After secret changes
docker compose down                                   # Stop; keep database data
```

Changing `POSTGRES_PASSWORD` does not update an existing database user's password.
**`docker compose down -v` permanently deletes the local database and other volumes.**

## Production

The production image builds from source and serves both the frontend and backend
on port **7007**. It uses `app-config.production.yaml`, not your local config.

1. Provision PostgreSQL. Set `POSTGRES_HOST` to an address reachable from the
   container; `localhost` points to the app container itself.
2. Supply the variables in [.env.example](../.env.example) through your hosting
   platform. Set `APP_BASE_URL` to your public URL, such as
   `https://backstage.example.com`.
3. Set the GitHub OAuth callback to
   `https://backstage.example.com/api/auth/github/handler/frame`.
4. Build the image and route HTTPS traffic to port **7007**.

```sh
docker build -t backstage:local .
```

To test the production image locally, use `.env.yarn` with reachable database
credentials:

```sh
docker run --rm --init --name backstage \
  --env-file .env.yarn \
  -e APP_BASE_URL=http://localhost:7007 \
  -p 127.0.0.1:7007:7007 \
  backstage:local
```

Open <http://localhost:7007>, test GitHub sign-in, and check readiness:

```sh
curl --fail http://localhost:7007/.backstage/health/v1/readiness
```

Before deploying, configure database TLS and backups, persistent TechDocs storage
(or an external publisher), and review the current allow-all permission policy.
Kubernetes setup comes later.
