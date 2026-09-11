# Troubleshooting and checks

[Back to README](../README.md)

Start with the terminal running `yarn start` and the browser's Console/Network
tabs. After backend dependency, registration, or configuration changes, stop and
restart the app before debugging further.

## Common failures

| Symptom                                    | What to do                                                                                                                                                                                |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Cannot resolve an imported backend package | Check `packages/backend/package.json`; install with `yarn --cwd packages/backend add <package>`. An import alone does not declare a dependency. See [plugin steps](how-to-add-plugin.md). |
| Plugin has no page                         | Check frontend package discovery, required extensions, and sidebar selection. Make sure the instructions target the new frontend system.                                                  |
| Catalog entity is missing                  | Check descriptor URL/path, repository access, allowed kinds, and catalog processing errors. See [catalog steps](how-to-add-catalog-entities.md).                                          |
| Catalog data disappears on restart         | Local SQLite is in memory. Add a configured source location or use a persistent database.                                                                                                 |
| GitHub discovery finds nothing             | Check `catalog.providers.github`, organization name, descriptor path, token access, and provider run logs.                                                                                |
| Template says an action is missing         | Check `/create/actions`; install/register the module providing that action, then restart.                                                                                                 |
| Template fails on `publish:github`         | Check token permissions, repository owner/name, and the GitHub scaffolder module. Inspect the failed step's log.                                                                          |
| Config change removes earlier entries      | Arrays replace rather than append. Include the full desired list in the overriding file.                                                                                                  |
| Environment variable is missing            | Export it in the launching shell or container environment. A `.env` file is not loaded automatically here.                                                                                |
| OAuth succeeds but sign-in fails           | Check the resolver and matching catalog `User`, plus provider callback URL and frontend sign-in setup.                                                                                    |
| Browser blocks backend requests            | Check public base URLs, CORS origin, auth session, and request errors.                                                                                                                    |
| TechDocs build fails                       | Check annotation, `mkdocs.yml`, repository access, and Docker availability.                                                                                                               |
| Kubernetes tab is empty                    | Check cluster connectivity, credentials/RBAC, and entity annotation/resource label matching.                                                                                              |
| Container fails to start                   | Check PostgreSQL environment/connectivity, imported dependencies, config files, and Node major version used for building.                                                                 |

## Run checks

From the repository root:

| Command               | Purpose                                                              |
| --------------------- | -------------------------------------------------------------------- |
| `yarn tsc`            | TypeScript check.                                                    |
| `yarn lint:all`       | Lint all workspaces. `yarn lint` checks changes since `origin/main`. |
| `yarn test`           | Workspace tests.                                                     |
| `yarn test:all`       | Tests with coverage.                                                 |
| `yarn prettier:check` | Repository formatting check.                                         |
| `yarn build:all`      | Build every workspace.                                               |
| `yarn test:e2e`       | Playwright browser tests.                                            |

For the first browser test run, install Playwright's browsers with
`yarn playwright install` (your OS may also need browser system dependencies).
[playwright.config.ts](../playwright.config.ts) starts app/backend servers locally.
In CI it expects an existing deployment; `PLAYWRIGHT_URL` overrides the default
target URL. Reports go into `e2e-test-report/`.

Frontend tests live under [packages/app/src/](../packages/app/src/) and browser
tests under [packages/app/e2e-tests/](../packages/app/e2e-tests/).
