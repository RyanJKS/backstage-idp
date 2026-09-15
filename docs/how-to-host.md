# Build and host Backstage

[Back to README](../README.md)

## Local development

You need Docker, Compose **2.30+**, your `app-config.local.yaml`, and the
`platform-blueprints` repository cloned alongside this repository.

From the repository root:

```sh
# First-time setup only; keep your existing .env.yarn if you already have one.
cp .env.example .env.yarn
```

Replace the placeholder credentials in `.env.yarn`, then start:

```sh
docker compose up --build
```

Open **<http://localhost:3000>**. The backend runs on port **7007**.

Compose reads `.env.yarn` for secrets and `app-config.local.yaml` for app settings.
It starts PostgreSQL automatically, uses separate dependency volumes, and mounts `../platform-blueprints` read-only for your local templates. Source edits reload automatically. Secrets stay out of the image.

Set your GitHub OAuth callback to `http://localhost:7007/api/auth/github/handler/frame`. Your GitHub username must match a User entity in `catalog/entities/users.yaml`.

```sh
docker compose logs -f backstage                       # View app logs
docker compose restart backstage                      # After dependency changes
docker compose up -d --force-recreate backstage        # After secret changes
docker compose down                                   # Stop; keep database data
```

Changing `POSTGRES_PASSWORD` does not update an existing database user's password.
**`docker compose down -v` permanently deletes the local database and other volumes.**

## Production

The production image packages artifacts built on the host or CI runner and serves both the frontend and backend on port **7007**. It uses `app-config.production.yaml`, not your local config. This follows the [Backstage host-build approach](https://backstage.io/docs/deployment/docker).

Use Node.js 24 and the repository's Yarn 4.13.0 for the host build. Docker installs production dependencies inside Linux, including native modules. Do not copy host `node_modules` into the image.

1. Provision PostgreSQL. Set `POSTGRES_HOST` to an address reachable from the
   container; `localhost` points to the app container itself.
2. Supply the variables in [.env.example](../.env.example) through your hosting
   platform. Set `APP_BASE_URL` to your public URL, such as
   `https://backstage.example.com`.
3. Set the GitHub OAuth callback to
   `https://backstage.example.com/api/auth/github/handler/frame`.
4. Build and publish the image in CI, then deploy its exact tag and route HTTPS
   traffic to port **7007**.

```sh
corepack enable
yarn install --immutable
yarn tsc
yarn build:backend --config ../../app-config.yaml
docker build --target production -t backstage:local .
```

Rebuild the artifacts after changing application code or build configuration.
`yarn build-image` packages those same artifacts; it does not compile the app.
The Docker context includes only the skeleton and bundle from the backend output,
while excluding secrets and host dependencies. Production dependencies use a
separate cached layer.

### CI and deployment

[The CI workflow](../.github/workflows/ci.yaml) installs dependencies, checks TypeScript, builds Backstage, and builds the image for pull requests.

After successful checks, pushes to `main` and manual runs call [the build and push workflow](../.github/workflows/build-push.yaml), which reuses the backend build artifacts and publishes to Docker Hub. Configure the repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` with permission to push images. Images use `<dockerhub-username>/chaos-generator:<6-character-sha>`. The workflow builds Linux AMD64 images.

Deploy the published tag, or its digest, through your hosting platform. Configure registry credentials when pulling a private package. Supply application secrets at runtime. Roll back by selecting a previously published image. CI does not apply Kubernetes manifests or change a running deployment.

### Local production check

To test the production image locally, use `.env.yarn` with reachable database
credentials:

```sh
docker run --rm --init --name backstage \
  --env-file .env.yarn \
  -e APP_BASE_URL=http://localhost:7007 \
  -p 127.0.0.1:7007:7007 \
  backstage:local
```

Open <http://localhost:7007>, test GitHub sign-in, and check readiness:

```sh
curl --fail http://localhost:7007/.backstage/health/v1/readiness
```

Before deploying, configure database TLS and backups, persistent TechDocs storage
(or an external publisher), and review the current allow-all permission policy.

## Kubernetes

Run these commands from the repository root. You need Helm, `kubectl` configured for your cluster, a default StorageClass for PostgreSQL storage, and an ingress controller for Backstage traffic. Publish the production image before deploying.

See the [resource map](../charts/README.md) to find each Kubernetes resource.

### 1. Add the Helm repository

```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Review the chart and configure PostgreSQL

Inspect the configuration for the pinned chart version:

```sh
helm show chart bitnami/postgresql --version 18.11.3
helm show values bitnami/postgresql --version 18.11.3 > /tmp/postgresql-default-values.yaml
```

Review `/tmp/postgresql-default-values.yaml`, then create or update [`charts/postgresql/values.yaml`](../charts/postgresql/values.yaml) with your overrides.

```sh
helm install <name> bitnami/postgresql --version 18.11.3 -n <namespace> --create-namespace
helm install psql bitnami/postgresql --version 18.11.3 -n backstage --create-namespace -f charts/postgresql/values.yaml

```

The existing file configures the `backstage` user and database, an **8Gi** persistent volume, and resource requests of **256Mi** memory and **100m** CPU. Choose the storage class and resources for your cluster. The values file references an existing Kubernetes Secret named `backstage-secrets`; it contains no passwords.

Helm uses `POSTGRES_PASSWORD` from that Secret for both the PostgreSQL
administrator and the `backstage` database user.

### 3. Apply the namespace and Secret

Reuse the repository's `.env.yarn` file and [.env.example](../.env.example). If you have not created it yet, follow the first-time setup above. Populate the GitHub credentials and `POSTGRES_PASSWORD`. For an existing database, use its current passwords. Keep values as unquoted `KEY=value` lines without `export`; Kustomize's env-file parser does not process dotenv quotes or shell substitutions.

The [charts/kustomization.yaml](../charts/kustomization.yaml) file declares the bootstrap resources. It applies [charts/namespace.yaml](../charts/namespace.yaml), which has `kind: Namespace`, and uses `secretGenerator` to produce a `kind: Secret` resource named `backstage-secrets` from `.env.yarn`. Kustomize is built into `kubectl`; no separate installation or credential YAML file is required.

```sh
kubectl apply -f charts/namespace.yaml

kubectl kustomize charts --load-restrictor LoadRestrictionsNone | kubectl apply --server-side --field-manager=backstage-secrets -f -

kubectl get namespace backstage
kubectl get secrets -n backstage
```

Run this from the repository root. The load-restrictor option lets Kustomize read `../.env.yarn` outside `charts/`; keep that file at the root as the single credential source. This applies only the namespace and Secret. Install PostgreSQL and apply Backstage in the next steps.

`.env.yarn` stays gitignored and excluded from Docker builds. Both Helm and Backstage reference the generated Secret's stable name. Backstage selects only its required credentials with `secretKeyRef`, so local database addresses do not override the Kubernetes Service address. Secret data is base64-encoded, not encrypted by that encoding; restrict access with Kubernetes RBAC and enable cluster encryption at rest. Avoid saving or sharing rendered Kustomize output, which includes secrets.

### 4. Install PostgreSQL with the values file

The release name is `psql` and the namespace is `backstage`:

```sh
helm install psql bitnami/postgresql --version 18.11.3 \
  -n backstage -f charts/postgresql/values.yaml
```

For another namespace, update `charts/namespace.yaml` and the `namespace` field in both Kustomization files, then use that namespace in the commands. If you change the Helm release name, update Backstage's `POSTGRES_HOST` to match. Keep the `-f` argument to apply your configuration. If the release already exists, use `helm upgrade` with the same chart version, namespace, and values file.

### 5. Check the PostgreSQL installation

```sh
kubectl get ns
helm status psql -n backstage
kubectl get pods -n backstage
kubectl get pvc -n backstage
```

Wait for the PostgreSQL pod to become ready. To open a shell for inspection:

```sh
kubectl exec -ti psql-postgresql-0 -n backstage -- sh
```

Use the actual pod name from `kubectl get pods` if it differs. Run `exit` to leave the pod shell before continuing.

### 6. Configure and deploy Backstage

Review the files in [`charts/backstage/`](../charts/backstage/) before applying:

- In `deployment.yaml`, set the image to the production image tag or digest you published.
- Set `POSTGRES_HOST` to the PostgreSQL Service name shown by
  `kubectl get svc -n backstage` (normally `psql-postgresql` for this release).
  Keep `POSTGRES_USER` aligned with the username in your Helm values. Both PostgreSQL and Backstage read the application password from `backstage-secrets`.
- Keep credentials in the Secret created above. The manifest already references them and supplies `POSTGRES_PORT=5432`. Review [.env.example](../.env.example) if you add other runtime settings.
- Replace `backstage.test.com` with your portal hostname in `APP_BASE_URL` and `ingress.yaml`. Configure the ingress class, DNS, and HTTPS/TLS for your cluster. Set the GitHub OAuth callback to the same public hostname as described above.

Apply the Deployment, Service, and Ingress, then check rollout and routing:

```sh
kubectl apply -k charts/backstage
kubectl rollout status deployment/backstage -n backstage
kubectl get pods -n backstage
kubectl get ing -n backstage
```

To update a single resource, target its file; for example,
`kubectl apply -f charts/backstage/ingress.yaml -n backstage`.

Open your configured portal URL and test GitHub sign-in. If the rollout fails, inspect `kubectl logs deployment/backstage -n backstage` and `kubectl describe pod <pod-name> -n backstage`.

### Update credentials

For GitHub credential changes, update `.env.yarn` and reapply the charts
Kustomization. The Secret keeps a stable name for Helm, so restart Backstage to
load the updated environment variables:

```sh
kubectl kustomize charts --load-restrictor LoadRestrictionsNone | \
  kubectl apply --server-side --field-manager=backstage-secrets -f -
kubectl rollout restart deployment/backstage -n backstage
kubectl rollout status deployment/backstage -n backstage
```

Changing `backstage-secrets` does not change passwords in an existing PostgreSQL
database. Coordinate database password rotation with the Secret update, then
restart Backstage. Do not delete the persistent volume to rotate a password.
For an existing installation, initially populate `.env.yarn` with the current
database passwords before switching Helm to the existing Secret.
