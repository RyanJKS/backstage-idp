# How to connect GitHub

[Back to README](../README.md)

GitHub repository access, catalog discovery, template publishing, and user login
are separate capabilities. Start with repository credentials, then enable the
capability you need.

## 1. Give Backstage repository access

The shared [app-config.yaml](../app-config.yaml) already contains:

```yaml
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
```

Set `GITHUB_TOKEN` using [configuration and secrets](how-to-configure.md). Give it
access to the relevant repositories; publishing also needs permission to create
and write repositories. Follow the
[GitHub integration guide](https://backstage.io/docs/integrations/github/locations/)
for token permissions or a GitHub App setup.

## 2. Discover repositories automatically

Install and register the catalog module if not already present:

```sh
yarn --cwd packages/backend add @backstage/plugin-catalog-backend-module-github
nvim packages/backend/src/index.ts
```

```ts
backend.add(import('@backstage/plugin-catalog-backend-module-github'));
```

Add a provider under the **existing** `catalog` key in `app-config.yaml`:

```yaml
catalog:
  providers:
    github:
      learningOrg:
        organization: YOUR_ORGANIZATION
        catalogPath: /catalog-info.yaml
        filters:
          repository: '.*'
        schedule:
          frequency: { minutes: 30 }
          timeout: { minutes: 3 }
```

Replace the organization placeholder. This example discovers descriptors in a
GitHub organization; repositories must contain the configured descriptor path.
Keep your existing `catalog.locations` and rules when adding this section.

Restart, check provider logs, and wait for a discovery run. Open the catalog and
look for an entity from the organization. A missing entity usually means missing
repository access, a missing descriptor, or a descriptor validation error.

To add just one repository, use the
[catalog import flow](how-to-add-catalog-entities.md) instead of discovery.

## 3. Let templates publish to GitHub

```sh
yarn --cwd packages/backend add @backstage/plugin-scaffolder-backend-module-github
nvim packages/backend/src/index.ts
```

```ts
backend.add(import('@backstage/plugin-scaffolder-backend-module-github'));
```

Keep the existing `@backstage/plugin-scaffolder-backend` registration. Restart and
open `/create/actions` in the frontend to check that `publish:github` is available.
The [example template](../examples/template/template.yaml) already uses it.
Executing that template creates a real repository in the selected GitHub location.

Next: [add a software template](how-to-add-template.md), or
[configure GitHub login](how-to-configure-auth.md).
