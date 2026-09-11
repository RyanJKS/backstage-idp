# How to configure the app

[Back to README](../README.md)

## Choose the right file

| File at repository root                                     | Purpose                                                                   |
| ----------------------------------------------------------- | ------------------------------------------------------------------------- |
| [app-config.yaml](../app-config.yaml)                       | Shared defaults, safe to commit.                                          |
| `app-config.local.yaml`                                     | Personal overrides and local credentials; create it yourself. Gitignored. |
| [app-config.production.yaml](../app-config.production.yaml) | Hosting overrides, safe to commit when secrets use variable references.   |

Default `yarn start` loads shared config and the optional local file. The Docker
entry point explicitly loads shared config followed by production config.
Explicit `--config` flags select the files to load; include every file you need.
Later files take precedence. Objects merge; **arrays replace the earlier array**.
This matters for `catalog.locations`, `integrations.github`, and `app.extensions`.

## Set a local secret

Choose either approach:

1. Set `GITHUB_TOKEN` in the shell or secret manager that launches `yarn start`.
   Shared config already references it as `${GITHUB_TOKEN}`. For example, this
   prompts without showing the token or putting its value in shell history:

   ```sh
   # zsh (the shell used for this workspace)
   read -rs 'GITHUB_TOKEN?GitHub token: '
   export GITHUB_TOKEN
   yarn start
   ```

2. Or create `app-config.local.yaml` at the root with your private value:

   ```yaml
   integrations:
     github:
       - host: github.com
         token: 'YOUR_GITHUB_TOKEN'
   ```

Replace the placeholder locally. This overrides the shared GitHub integration
list. Do not commit or copy the populated file into an image. A `.env` file alone
does not supply variables: Backstage does not automatically load it here.

## Change a setting

1. Open the appropriate config file, for example `nvim app-config.local.yaml`.
2. Add only the override you need. For example:

   ```yaml
   app:
     title: My Learning Portal
   ```

3. Restart the app and verify the change in the browser and startup logs.

| Setting               | Meaning                                                        |
| --------------------- | -------------------------------------------------------------- |
| `app.baseUrl`         | URL users open in their browser.                               |
| `backend.baseUrl`     | Public URL the browser uses to reach the backend.              |
| `backend.listen`      | Address/port the backend binds to.                             |
| `backend.cors.origin` | Allowed frontend origin for cross-origin requests.             |
| `backend.database`    | SQLite locally; PostgreSQL in the production config.           |
| `catalog.locations`   | Sources of entity descriptors, not a list of running services. |

For hosting, provide `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, and
`POSTGRES_PASSWORD` through the runtime environment. Auth and additional services
may require more variables; each how-to names them as they are introduced.

See [Backstage configuration](https://backstage.io/docs/conf/) and
[hosting](how-to-host.md).
