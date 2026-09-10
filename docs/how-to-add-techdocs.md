# How to add service documentation

[Back to README](../README.md)

TechDocs builds documentation from a service repository and displays it in the
portal. These Markdown how-to files are repository documentation; they are not
automatically registered as a TechDocs site.

## Add docs to a service

1. In the **service repository**, add this annotation to its `catalog-info.yaml`:

   ```yaml
   metadata:
     annotations:
       backstage.io/techdocs-ref: dir:.
   ```

   Merge it into the entity's existing metadata; keep its name and other fields.

2. Add `mkdocs.yml` next to that descriptor:

   ```yaml
   site_name: My Service
   nav:
     - Home: index.md
   plugins:
     - techdocs-core
   ```

3. Create `docs/index.md` in that service repository with some documentation.
4. Commit those files and [register the service](how-to-add-catalog-entities.md).
   Backstage needs repository read access to fetch them.

## Check the Backstage wiring

The TechDocs frontend package and backend registration already exist here. If
setting them up again, the steps are:

```sh
yarn --cwd packages/app add @backstage/plugin-techdocs
yarn --cwd packages/backend add @backstage/plugin-techdocs-backend
nvim packages/backend/src/index.ts
```

Keep one registration:

```ts
backend.add(import('@backstage/plugin-techdocs-backend'));
```

The current config uses:

```yaml
techdocs:
  builder: local
  generator:
    runIn: docker
  publisher:
    type: local
```

Start Docker, restart Backstage if you changed wiring/config, then open the
entity's Docs tab. The first visit can trigger a build. Check backend logs for
repository access, MkDocs, or Docker failures.

## Host docs

1. Build documentation in CI with the TechDocs toolchain.
2. Publish output to supported shared storage such as S3 or Google Cloud Storage.
3. Set `techdocs.builder: external` and configure `techdocs.publisher` for the same
   storage and runtime credentials.
4. Verify the hosted portal can read a published site after restarting the backend.

The backend Docker image does not automatically provide a Docker daemon for the
local generator. Use the
[TechDocs deployment guide](https://backstage.io/docs/features/techdocs/how-to-guides/)
for the full CI/storage setup.
