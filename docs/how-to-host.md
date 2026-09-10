# How to build and host Backstage

[Back to README](../README.md)

The backend serves the bundled frontend in production. The repository supplies a
Dockerfile and production config, but no deployment manifests or hosting pipeline.

## 1. Build the image

Use **Node.js 24**, matching the Docker image's Node major version for native
dependencies. From the repository root:

```sh
yarn install --immutable
yarn tsc
yarn build:backend
yarn build-image
```

This builds the image tagged `backstage`. The
[Dockerfile](../packages/backend/Dockerfile) packages those build outputs; it does
not build the source from scratch.

## 2. Prepare runtime configuration

Edit [app-config.production.yaml](../app-config.production.yaml) before building,
or mount a deployment-specific override into the container and pass it with an
additional `--config` argument after the shared and production files.

| Setting                             | Required action                                                                                      |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `app.baseUrl` and `backend.baseUrl` | Set the actual public URLs. The defaults are `http://localhost:7007`.                                |
| `backend.cors.origin`               | Set the actual frontend origin if needed; the shared value is the development URL.                   |
| `backend.database`                  | Provision PostgreSQL and supply the variables below.                                                 |
| `auth`                              | Configure real login and identity resolution. The guest placeholder is not a production login setup. |
| `catalog.locations`                 | Replace or extend sample sources. Container file paths start with `./examples/`.                     |
| `techdocs`                          | Choose CI builds and shared storage for hosted use.                                                  |

Supply these variables through the hosting platform's secrets/environment settings:

```text
POSTGRES_HOST
POSTGRES_PORT
POSTGRES_USER
POSTGRES_PASSWORD
GITHUB_TOKEN
```

Include variables for any auth provider and other integrations you configured.
The PostgreSQL host must be reachable **from inside the container**; `localhost`
there means the container itself. Give the database account the privileges needed
for Backstage's plugin databases/schema migrations, and configure TLS as required
by your database provider.

Follow [authentication](how-to-configure-auth.md) and
[TechDocs](how-to-add-techdocs.md) before exposing those capabilities to users.
Permissions are enabled here, but the registered policy allows all requests.

## 3. Run the container

After exporting the variables above in your launch environment, this is a basic
local image run command:

```sh
docker run --rm --name backstage -p 7007:7007 \
  -e POSTGRES_HOST -e POSTGRES_PORT -e POSTGRES_USER -e POSTGRES_PASSWORD \
  -e GITHUB_TOKEN \
  backstage
```

Add `-e` arguments for any additional variables referenced by your config. This
command starts only Backstage: PostgreSQL must already exist. The image loads
`app-config.yaml` followed by `app-config.production.yaml`; it excludes local
override files.

For a hosted deployment, publish the image to your registry, deploy it through
your platform, route HTTPS traffic to port 7007, and configure restart behavior,
database persistence/backups, logs, and health monitoring.

## 4. Verify the deployment

1. Check container logs for configuration, database, and missing-package errors.
2. Open the public portal URL and test real login and identity resolution.
3. Verify catalog ingestion, a test template, search, and documentation.
4. Restart the container and confirm database-backed data remains available.

Next: automate checks and image publishing in CI. See
[Backstage deployment](https://backstage.io/docs/deployment/),
[Docker](https://backstage.io/docs/deployment/docker/), and
[keeping Backstage updated](https://backstage.io/docs/getting-started/keeping-backstage-updated/).
