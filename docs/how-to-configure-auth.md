# How to configure login and permissions

[Back to README](../README.md)

The current app uses Guest login. Repository integration credentials such as
`GITHUB_TOKEN` do not sign users into Backstage.

## Add GitHub login

1. Create a GitHub OAuth App with your local frontend URL
   `http://localhost:3000` as its homepage and this callback URL:

   ```text
   http://localhost:7007/api/auth/github/handler/frame
   ```

   For hosting, use your deployed URLs and a matching OAuth App configuration.

2. Install the backend provider:

   ```sh
   yarn --cwd packages/backend add @backstage/plugin-auth-backend-module-github-provider
   nvim packages/backend/src/index.ts
   ```

3. Register it once, alongside the existing auth backend:

   ```ts
   backend.add(import('@backstage/plugin-auth-backend-module-github-provider'));
   ```

4. Merge this into the existing `auth` configuration, and supply the variables
   using [configuration and secrets](how-to-configure.md):

   ```yaml
   auth:
     environment: development
     providers:
       github:
         development:
           clientId: ${AUTH_GITHUB_CLIENT_ID}
           clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
           signIn:
             resolvers:
               - resolver: usernameMatchingUserEntityName
   ```

5. Add a catalog `User` with `metadata.name` matching your GitHub username, or
   configure an organization provider that supplies matching users. The resolver
   above requires this identity match; being able to authenticate with GitHub
   alone is not enough. See [catalog entities](how-to-add-catalog-entities.md).
6. Replace the default Guest sign-in page with a local frontend module. Create
   `packages/app/src/modules/signIn.tsx`:

   ```tsx
   import { createFrontendModule } from '@backstage/frontend-plugin-api';
   import { SignInPageBlueprint } from '@backstage/plugin-app-react';
   import { SignInPage } from '@backstage/core-components';
   import { githubAuthApiRef } from '@backstage/core-plugin-api';

   export const signInModule = createFrontendModule({
     pluginId: 'app',
     extensions: [
       SignInPageBlueprint.make({
         params: {
           loader: async () => props =>
             (
               <SignInPage
                 {...props}
                 providers={[
                   {
                     id: 'github-auth-provider',
                     title: 'GitHub',
                     message: 'Sign in using GitHub',
                     apiRef: githubAuthApiRef,
                   },
                 ]}
               />
             ),
         },
       }),
     ],
   });
   ```

   In [App.tsx](../packages/app/src/App.tsx), import it with
   `import { signInModule } from './modules/signIn';` and append `signInModule` to
   the existing `features` array. This overrides the app's default sign-in page
   extension. The packages used above are already frontend dependencies here.
   Run `yarn tsc` after making these edits.

7. Restart, sign out of the Guest session, and sign in with GitHub. Verify your
   identity in Settings and check the backend logs if the resolver fails.
8. Once real login works, remove Guest from frontend sign-in options and remove
   its backend module registration and config from the applicable files. For
   production, use an auth environment and provider config matching the deployment.

See the [GitHub auth provider guide](https://backstage.io/docs/auth/github/provider/)
for provider-specific options and sign-in resolver choices.

## Restrict what signed-in users can do

`permission.enabled: true` is already set, but
`@backstage/plugin-permission-backend-module-allow-all-policy` allows all requests.
Login and authorization are separate changes.

1. Follow the [permission policy guide](https://backstage.io/docs/permissions/getting-started/)
   to implement a policy module for the new backend system.
2. Install/register your policy module in `packages/backend/src/index.ts`.
3. Remove the existing allow-all policy registration; only one policy should be
   active. Keep the permission backend and `permission.enabled: true`.
4. Verify both allowed and denied actions with representative users, including
   direct backend requests where relevant.
