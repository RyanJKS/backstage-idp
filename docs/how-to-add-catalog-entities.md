# How to add catalog entities

[Back to README](../README.md)

The catalog describes software and ownership. It does not deploy the software.

## Add a service from a repository

1. Create `catalog-info.yaml` in the service's repository:

   ```yaml
   apiVersion: backstage.io/v1alpha1
   kind: Component
   metadata:
     name: my-service
     description: My learning service
   spec:
     type: service
     lifecycle: experimental
     owner: user:default/guest
   ```

2. Commit the descriptor to that service repository. Replace the example owner
   with a real catalog user/group when available.
3. In Backstage, open `/catalog-import`, enter the descriptor's repository URL,
   and complete registration. For private GitHub repositories, first
   [configure GitHub access](how-to-connect-github.md).
4. Open the entity in the catalog. Check its metadata, owner, and processing
   errors. Catalog ingestion is asynchronous, so allow time for processing.

## Show GitHub Actions for an entity

The GitHub Actions plugin is registered in the new frontend system. Its tab appears
on an entity page only when the entity has this annotation:

```yaml
metadata:
  annotations:
    github.com/project-slug: YOUR_ORG/YOUR_REPO
```

Use the repository's actual owner and name, not a URL. Update the descriptor in
that repository and refresh the entity in the catalog. Open the entity's
**GitHub Actions** tab; the plugin does not add a sidebar item. Sign in with GitHub
to load workflow runs, using an account that can access the repository.

The portal's own descriptor includes `RyanJKS/backstage-idp`. Local development
loads it through `app-config.local.yaml`. Other imported repositories need their
own annotation. A repository without workflow runs shows an empty list.

## Load a local example at startup

1. Add an entity to [examples/entities.yaml](../examples/entities.yaml), separating
   YAML documents with `---`. This file is already a catalog location.
2. Or create another descriptor and append a location to the **existing**
   `catalog.locations` list in [app-config.yaml](../app-config.yaml):

   ```yaml
   - type: file
     target: ../../examples/my-service.yaml
   ```

3. Restart and verify the entity appears. File paths are relative to the backend
   process (`packages/backend` locally). In the container, add the corresponding
   `./examples/my-service.yaml` entry in the production location list.

The portal's root [catalog-info.yaml](../catalog-info.yaml) is also just a
descriptor. To load it locally, use the same location pattern with
`target: ../../catalog-info.yaml`. Container use additionally needs that file
copied into the image and a matching production path.

## Add users, groups, APIs, or resources

1. Use [examples/org.yaml](../examples/org.yaml) for local `User` and `Group`
   examples. Set service `spec.owner` values to their entity references, such as
   `group:default/my-team`.
2. Use the appropriate entity kind and required `spec` fields from the
   [descriptor format](https://backstage.io/docs/features/software-catalog/descriptor-format/)
   for `API`, `Resource`, and `System` entities.
3. Check catalog rules allow the kind. The shared global rules permit `Component`,
   `System`, `API`, `Resource`, and `Location`; the org and template locations have
   their own rules permitting `User`/`Group` and `Template`.
4. Verify entity relationships in the UI after ingestion.

Local SQLite is in memory. UI-only registrations disappear after restart; file
locations are loaded again. Use configured sources or a persistent database for
data you want to retain.

Full example on how to add groups: https://github.com/backstage/backstage/blob/master/packages/catalog-model/examples/acme/team-a-group.yaml
