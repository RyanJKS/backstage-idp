# How to add a software template

[Back to README](../README.md)

A template collects inputs, runs backend actions, and links to the result.

1. Copy [examples/template/](../examples/template/) to a new directory under
   `examples/`, such as `examples/my-template/`.
2. Edit its `template.yaml`:
   - Give `metadata.name` a unique value and update its title/description.
   - Set `spec.parameters` to the form fields you need.
   - Set `spec.steps` to the actions to execute.
   - Set `spec.output.links` to the resulting repository and catalog entity.
3. Edit the copied `content/` files. These are the files written into the new
   repository. `${{ values.name }}` uses a value passed by the `fetch:template`
   step. Keep the generated `catalog-info.yaml` consistent with the project.
4. Install and register any action modules used by the steps. The example uses
   `publish:github`; follow [Connect GitHub](how-to-connect-github.md). It also uses
   `notification:send`, supplied by:

   ```sh
   yarn --cwd packages/backend add @backstage/plugin-scaffolder-backend-module-notifications
   ```

   In [packages/backend/src/index.ts](../packages/backend/src/index.ts), keep one
   registration (already present here):

   ```ts
   backend.add(
     import('@backstage/plugin-scaffolder-backend-module-notifications'),
   );
   ```

   Keep the notifications backend wired too if retaining that step. Remove the
   step from your copied template if you do not want notifications.

5. Append the new template to `catalog.locations` in `app-config.yaml`:

   ```yaml
   - type: file
     target: ../../examples/my-template/template.yaml
     rules:
       - allow: [Template]
   ```

   For container use, also add its `./examples/my-template/template.yaml` location
   to `app-config.production.yaml`.

6. Restart and open `/create`. Check `/create/actions` for the actions your
   template needs, then run it with a test repository name. Publishing creates a
   real GitHub repository.
7. Inspect the task's step logs and verify the repository files and catalog entity.

See [Software Templates](https://backstage.io/docs/features/software-templates/)
for custom actions, validation, and template testing.
