# How to add a plugin

[Back to README](../README.md)

Remember: **install → register → configure → restart → verify**.
Run commands from the repository root. If a package or registration already
exists, keep it once; you do not need to add it again.

## Backend plugin or module

1. Install in the backend workspace. Replace `<package-name>` with the package
   from the plugin's installation guide:

   ```sh
   yarn --cwd packages/backend add <package-name>
   ```

2. Open [packages/backend/src/index.ts](../packages/backend/src/index.ts):

   ```sh
   nvim packages/backend/src/index.ts
   ```

3. Add its registration alongside the related plugin, **before `backend.start()`**:

   ```ts
   backend.add(import('<package-name>'));
   ```

   A module extends a plugin, so the parent plugin must also be installed and
   registered. Follow the package's guide if it needs more than this registration.

4. Add the required settings to [app-config.yaml](../app-config.yaml) and secrets
   to your environment or `app-config.local.yaml`.
5. Stop and restart `yarn start`, then exercise the feature and check backend logs.
6. Run `yarn tsc`. Review changes to the backend manifest, `yarn.lock`, the entry
   point, and shared config together.

## The two GitHub modules

For repository discovery in the catalog:

```sh
yarn --cwd packages/backend add @backstage/plugin-catalog-backend-module-github
nvim packages/backend/src/index.ts
```

```ts
backend.add(import('@backstage/plugin-catalog-backend-module-github'));
```

For GitHub actions such as `publish:github` in software templates:

```sh
yarn --cwd packages/backend add @backstage/plugin-scaffolder-backend-module-github
nvim packages/backend/src/index.ts
```

```ts
backend.add(import('@backstage/plugin-scaffolder-backend-module-github'));
```

Both registrations are present in this checkout. Their configuration and
verification steps are in [Connect GitHub](how-to-connect-github.md).

## Frontend plugin

1. Find a plugin that supports the [new frontend system](https://backstage.io/docs/frontend-system/).
2. Install it in the app workspace:

   ```sh
   yarn --cwd packages/app add <frontend-package>
   ```

3. Check the plugin's installation instructions. This app has `app.packages: all`
   in `app-config.yaml`, so compatible installed frontend features are discovered
   automatically. Add explicit imports to
   [App.tsx](../packages/app/src/App.tsx) only where required. Local modules such as
   `navModule` and `homeModule` are explicitly listed in `features`.
4. Configure the plugin's extensions under `app.extensions`. If it needs a backend
   package, follow the backend steps above too.
5. Restart and check its page or entity tab. For navigation changes, see
   [Customize the frontend](how-to-customize-frontend.md).

## Build your own

Run `yarn new` and select the appropriate plugin/module template. Reusable code
belongs in [plugins/](../plugins/); app-specific frontend modules can live in
[packages/app/src/modules/](../packages/app/src/modules/). Install and wire the
generated package into each consuming workspace using its generated instructions.

Browse the [plugin directory](https://backstage.io/plugins) and
[backend system documentation](https://backstage.io/docs/backend-system/).
