# Kubernetes resources

| File                                                         | Purpose                                                                                              |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| [namespace.yaml](namespace.yaml)                             | Creates the `backstage` namespace.                                                                   |
| [kustomization.yaml](kustomization.yaml)                     | Applies the namespace and generates `backstage-secrets` from the existing, ignored `.env.yarn` file. |
| [postgresql/values.yaml](postgresql/values.yaml)             | Configures the Bitnami PostgreSQL Helm chart and references the generated Secret.                    |
| [backstage/deployment.yaml](backstage/deployment.yaml)       | Defines the Backstage image, environment, and Secret references.                                     |
| [backstage/service.yaml](backstage/service.yaml)             | Exposes Backstage inside the cluster.                                                                |
| [backstage/ingress.yaml](backstage/ingress.yaml)             | Routes the public hostname to the Service.                                                           |
| [backstage/kustomization.yaml](backstage/kustomization.yaml) | Groups the Backstage resources for `kubectl apply -k charts/backstage`.                              |

Deploy in order: namespace and Secret, PostgreSQL, then Backstage. The charts
Kustomization only manages the first step. This directory contains deployment
resources and Helm values, not a custom Helm chart.

See [Build and host Backstage](../docs/how-to-host.md#kubernetes) for setup,
deployment commands, and credential updates.
