# Backstage IDP

My workspace for learning Backstage, adding features, and hosting a developer portal.

## Start the app

Run commands from the **repository root**. Use **Node.js 24** (Node 22 is also
supported for development) and the repository's **Yarn 4.13.0**.

```sh
# First run / after pulling dependency changes
corepack enable
yarn install --immutable

# Start frontend + backend
yarn start
```

Open **<http://localhost:3000>**. The backend runs at **<http://localhost:7007>**. All actions are here: **http://localhost:3000/create/actions**
Stop with `Ctrl+C`.

| Command              | When to use it                                      |
| -------------------- | --------------------------------------------------- |
| `yarn start app`     | Run only the frontend.                              |
| `yarn start backend` | Run only the backend.                               |
| `yarn tsc`           | Check TypeScript after code changes.                |
| `yarn lint:all`      | Lint all workspaces.                                |
| `yarn test`          | Run workspace tests.                                |
| `yarn new`           | Scaffold a plugin or module.                        |
| `yarn build:backend` | Build the backend and bundled frontend for hosting. |

Local login uses **Guest**. Local catalog data lives in **in-memory SQLite** and
is reloaded from configured sources after restart.

## Files to remember

| Location                                                                                                                | What goes here                                                                                                        |
| ----------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| [app-config.yaml](app-config.yaml)                                                                                      | Shared settings: plugins, catalog sources, URLs, integrations, and UI extensions.                                     |
| `app-config.local.yaml` (create at the root)                                                                            | Your local overrides and secrets; gitignored.                                                                         |
| [app-config.production.yaml](app-config.production.yaml)                                                                | Hosting overrides: public URLs, PostgreSQL, and container catalog paths.                                              |
| [packages/backend/src/index.ts](packages/backend/src/index.ts)                                                          | Register backend plugins and modules with `backend.add(...)`.                                                         |
| [packages/app/src/App.tsx](packages/app/src/App.tsx)                                                                    | Register local frontend features; installed plugins can also be discovered automatically.                             |
| [packages/app/src/modules/](packages/app/src/modules/)                                                                  | Custom home widgets, sidebar, and logos.                                                                              |
| [packages/app/package.json](packages/app/package.json) / [packages/backend/package.json](packages/backend/package.json) | Install dependencies in the workspace that uses them. Root [package.json](package.json) holds shared scripts/tooling. |
| [catalog-info.yaml](catalog-info.yaml)                                                                                  | Catalog metadata describing this portal; it still needs registering.                                                  |
| [examples/](examples/)                                                                                                  | Sample services, users/groups, and software template files.                                                           |
| [plugins/](plugins/)                                                                                                    | Your own reusable plugins/modules.                                                                                    |
| [packages/backend/Dockerfile](packages/backend/Dockerfile)                                                              | Container packaging.                                                                                                  |

## Where do configs and environment variables go?

- Put shared, non-secret settings in `app-config.yaml`.
- Put personal overrides in a root `app-config.local.yaml`.
- `${GITHUB_TOKEN}` in YAML reads an environment variable from the process running
  Backstage. Export it before `yarn start`, or override the integration token in
  `app-config.local.yaml`. A `.env` file is **not automatically loaded**.
- Production needs `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, and
  `POSTGRES_PASSWORD`, plus credentials for your integrations. Set these through
  the hosting platform.

See [configuration and secrets](docs/how-to-configure.md) for examples and override rules.

## How do I…?

| Task                                             | Guide                                                         |
| ------------------------------------------------ | ------------------------------------------------------------- |
| Install and register a plugin                    | [Add a plugin](docs/how-to-add-plugin.md)                     |
| Connect GitHub for discovery or project creation | [Connect GitHub](docs/how-to-connect-github.md)               |
| Set config, secrets, or environment variables    | [Configure the app](docs/how-to-configure.md)                 |
| Add a service, API, user, or group               | [Add catalog entities](docs/how-to-add-catalog-entities.md)   |
| Create a project from a template                 | [Add a software template](docs/how-to-add-template.md)        |
| Change the home page, sidebar, or branding       | [Customize the frontend](docs/how-to-customize-frontend.md)   |
| Set up login and permissions                     | [Configure authentication](docs/how-to-configure-auth.md)     |
| Add service documentation                        | [Set up TechDocs](docs/how-to-add-techdocs.md)                |
| Configure search, Kubernetes, or an API proxy    | [Connect other capabilities](docs/how-to-connect-services.md) |
| Build a container and host Backstage             | [Build and host](docs/how-to-host.md)                         |
| Debug a failure or run checks                    | [Troubleshoot](docs/troubleshooting.md)                       |

This app uses Backstage's **new frontend and backend systems**. Check that tutorials
match these systems before copying wiring examples.
