# How to connect search, Kubernetes, and external APIs

[Back to README](../README.md)

## Search catalog entities and TechDocs

Search uses a backend, a search engine, and **collators** that collect documents
for indexing. The following registrations are already in the backend entry point.
When enabling them in another setup, install their packages first:

```sh
yarn --cwd packages/backend add @backstage/plugin-search-backend @backstage/plugin-search-backend-module-pg @backstage/plugin-search-backend-module-catalog @backstage/plugin-search-backend-module-techdocs
nvim packages/backend/src/index.ts
```

Keep one registration for each:

```ts
backend.add(import('@backstage/plugin-search-backend'));
backend.add(import('@backstage/plugin-search-backend-module-pg'));
backend.add(import('@backstage/plugin-search-backend-module-catalog'));
backend.add(import('@backstage/plugin-search-backend-module-techdocs'));
```

1. Check `@backstage/plugin-search` is installed in `packages/app/package.json`;
   if missing, run `yarn --cwd packages/app add @backstage/plugin-search`.
2. Choose the engine for your environment. The PostgreSQL module uses PostgreSQL
   when supported by the configured database; local SQLite uses the default
   in-memory search engine. See the
   [search engine guide](https://backstage.io/docs/features/search/search-engines/).
3. Populate the catalog and publish/build TechDocs before expecting results.
4. Restart and check indexing logs. Allow a collator run to complete, then search
   for a known entity or document through the sidebar search.
5. For a new source of searchable data, install/register its collator or write one;
   installing its UI plugin alone does not index its data.

## Connect a Kubernetes cluster

1. Check/install the frontend and backend packages:

   ```sh
   yarn --cwd packages/app add @backstage/plugin-kubernetes
   yarn --cwd packages/backend add @backstage/plugin-kubernetes-backend
   ```

2. Keep the existing registration in `packages/backend/src/index.ts`:

   ```ts
   backend.add(import('@backstage/plugin-kubernetes-backend'));
   ```

3. Under the existing `kubernetes` key in `app-config.yaml`, configure a cluster
   locator. For example, for a service-account-based connection:

   ```yaml
   kubernetes:
     serviceLocatorMethod:
       type: multiTenant
     clusterLocatorMethods:
       - type: config
         clusters:
           - url: https://YOUR_CLUSTER_API
             name: learning-cluster
             authProvider: serviceAccount
             serviceAccountToken: ${K8S_SERVICE_ACCOUNT_TOKEN}
   ```

4. Replace the API URL, supply the token privately, and configure trusted cluster
   certificates and read permissions for the resources you want to display.
   Follow the [Kubernetes configuration guide](https://backstage.io/docs/features/kubernetes/configuration/)
   for the required RBAC and your cluster's authentication method.
5. Add `backstage.io/kubernetes-id: my-service` to the catalog entity's
   `metadata.annotations`. Add the matching `backstage.io/kubernetes-id: my-service`
   label to the Kubernetes resources you want to associate with it.
6. Restart and inspect the entity's Kubernetes tab. Check API connectivity, token
   permissions, and matching resource labels if it is empty.

## Proxy an external API

1. Keep `@backstage/plugin-proxy-backend` installed in the backend and registered
   with `backend.add(import('@backstage/plugin-proxy-backend'))`; both exist here.
2. Add an endpoint under the existing `proxy` key:

   ```yaml
   proxy:
     endpoints:
       '/learning-api':
         target: https://api.example.com
         changeOrigin: true
   ```

3. Replace the target and add any required backend-only credentials using
   [configuration and secrets](how-to-configure.md).
4. Call the `/api/proxy/learning-api/...` backend route from your frontend feature
   using Backstage's discovery and authenticated fetch APIs.
5. Restart and check the response in browser network tools and backend logs.
   Use a custom backend plugin when you need business logic or resource-level
   authorization beyond the proxy's capabilities.

See [proxy configuration](https://backstage.io/docs/plugins/proxying/).
