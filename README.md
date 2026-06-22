# Netmaker Helm

![Version: 1.6.0](https://img.shields.io/badge/Version-1.6.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.6.0](https://img.shields.io/badge/AppVersion-1.6.0-informational?style=flat-square)

A Helm chart to run Netmaker with High Availability on Kubernetes


## Requirements

To run HA Netmaker on Kubernetes, your cluster must have the following:
- RWO and RWX Storage Classes
- An Ingress Controller and valid TLS certificates 
	- This chart can currently generate ingress for:
		- Nginx Ingress + LetsEncrypt/Cert-Manager
	- to generate automatically, make sure one of the two is configured for your cluster
- Ability to set up DNS for Secure Web Sockets
	- Nginx Ingress supports Secure Web Sockets (WSS) by default. If you are not using Nginx Ingress, you must route external traffic from broker.domain to the MQTT service, and provide valid TLS certificates.
	- One option is to set up a Load Balancer which routes broker.domain:443 to the MQTT service on port 8883.
	- We do not provide guidance beyond this, and recommend using an Ingress Controller that supports websockets.

Furthermore, the chart will by default deploy a single PostgreSQL instance using the official `postgres` image as its datastore.

## PostgreSQL

### What changed in chart 1.6.0

Chart **1.6.0** removes the Bitnami `postgresql-ha` subchart. The following values are **deprecated and no longer supported**:

| Deprecated (≤ 1.5.x) | Replacement (1.6.0) |
|----------------------|------------------------|
| `postgresql-ha.enabled` | `postgres.enabled` |
| `postgresql-ha.postgresql.*` | `db.username`, `db.password`, `db.database` |
| `postgresql-ha.persistence.size` | `postgres.storageSize` |
| `postgresql-ha.pgpool.*` | *(removed)* |

When `postgres.enabled=true` (default), the chart deploys a **single-replica** PostgreSQL StatefulSet using the official [`postgres`](https://hub.docker.com/_/postgres) image. This is intended for **development, testing, and quick starts** only.

### Production recommendations

For production workloads, **do not rely on the bundled PostgreSQL**. Use a dedicated database layer instead, for example:

- **[CloudNativePG](https://cloudnative-pg.io/)** — PostgreSQL operator for Kubernetes (HA, backups, failover)
- **Managed PostgreSQL** — AWS RDS, Google Cloud SQL, Azure Database for PostgreSQL, DigitalOcean Managed Databases, etc.

Point Netmaker at your external database:

```bash
helm install netmaker netmaker/netmaker \
  --set baseDomain=nm.example.com \
  --set postgres.enabled=false \
  --set db.host=<your-postgres-host> \
  --set db.port=5432 \
  --set db.username=postgres \
  --set db.password=<your-password> \
  --set db.database=netmaker
```

Or supply credentials from an existing Kubernetes Secret:

```bash
helm install netmaker netmaker/netmaker \
  --set baseDomain=nm.example.com \
  --set postgres.enabled=false \
  --set db.existingSecret.enabled=true \
  --set db.existingSecret.name=<secret-name>
```

**Note:** `postgres.enabled` and `db.host` are mutually exclusive. Set `postgres.enabled=false` whenever using an external or operator-managed database.


### Recommended Settings:

This install has some notable exceptions:
- Ingress **must** be configured on your cluster, with cluster issuer for TLS certs


#### MQ

The MQ Broker is deployed either with Ingress (Nginx ) preconfigured, or without. If you are using an ingress controller other than Nginx, Netmaker's MQTT will not be complete. "broker.domain"  must reach the MQTT service at port 8883 over WSS (Secure Web Sockets).

#### Ingress	
To run HA Netmaker, you must have ingress installed and enabled on your cluster with valid TLS certificates (not self-signed). If you are running Nginx as your Ingress Controller and LetsEncrypt for TLS certificate management, you can run the helm install with the following settings:
`--set ingress.enabled=true`
`--set ingress.className=nginx`
`--set ingress.annotations.cert-manager.io/cluster-issuer=<your LE issuer name>`

If you are not using Nginx and LetsEncrypt, we recommend leaving ingress.enabled=false (default), and then manually creating the ingress objects post-install. You will need three ingress objects with TLS:
`dashboard.<baseDomain>`
`api.<baseDomain>`
`broker.<baseDomain>`

#### Cert-Manager ClusterIssuer

This chart can optionally create a Let's Encrypt ClusterIssuer for cert-manager. This is useful if you don't already have a ClusterIssuer configured in your cluster.

To enable the ClusterIssuer:
```bash
--set certManager.enabled=true
--set certManager.email=your-email@example.com
```

The ClusterIssuer will be created with the name specified in `certManager.issuerName` (default: `letsencrypt-prod`) and will use HTTP-01 challenge for domain validation.

**Note:** If you already have a ClusterIssuer in your cluster, leave `certManager.enabled=false` and just set the ingress annotation to reference your existing issuer:
`--set ingress.annotations.cert-manager\.io/cluster-issuer=<your-issuer-name>`



## Install Command

```bash

helm repo add netmaker https://gravitl.github.io/netmaker-helm/

helm repo update

helm install netmaker netmaker/netmaker --set baseDomain=nm.example.com --set server.replicas=3 --set ingress.enabled=true --set ingress.className=nginx --set ingress.annotations.cert-manager\.io/cluster-issuer=letsencrypt-prod --set postgres.enabled=true --set db.username=postgres --set db.password=password123 --set ui.image.repository=gravitl/netmaker-ui --set ui.image.pullPolicy=Always --set ui.image.tag=latest --set server.image.repository=gravitl/netmaker --set server.image.pullPolicy=Always --set server.image.tag=latest --namespace netmaker --create-namespace

```

## Verification

Check installation status:

```bash
kubectl get pods -n netmaker
kubectl get svc -n netmaker
```

## Uninstall

```bash
helm uninstall netmaker -n netmaker
kubectl delete namespace netmaker
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| certManager.enabled | bool | `false` | whether to create a ClusterIssuer for cert-manager |
| certManager.issuerName | string | `"letsencrypt-prod"` | name of the ClusterIssuer to create |
| certManager.email | string | `""` | email address for Let's Encrypt registration (required if enabled) |
| db.sslmode | string | `"disable"` | postgres sslmode (disable, require, verify-ca, verify-full) |
| dns.enabled | bool | `false` | whether or not to run with DNS (CoreDNS) |
| dns.storageSize | string | `"128Mi"` | volume size for DNS (only needs to hold one file) |
| fullnameOverride | string | `""` | override the full name for netmaker objects  |
| image.pullPolicy | string | `"Always"` | Pull Policy for images |
| image.repository | string | `"gravitl/netmaker"` | The image repo to pull Netmaker image from  |
| image.tag | string | `"latest"` | Override the image tag to pull  |
| ingress.className | string | `"nginx"` | ingress class name (e.g. nginx, traefik) |
| ingress.annotations."cert-manager.io/cluster-issuer" | string | `"letsencrypt-prod"` | cert manager cluster issuer name |
| ingress.enabled | bool | `false` | attempts to configure ingress if true |
| ingress.hostPrefix.mq | string | `"broker"` | broker route subdomain |
| ingress.hostPrefix.rest | string | `"api"` | api (REST) route subdomain |
| ingress.hostPrefix.ui | string | `"dashboard"` | ui route subdomain |
| ingress.tls | bool | `true` |  |
| nameOverride | string | `""` | override the name for netmaker objects  |
| podAnnotations | object | `{}` | pod annotations to add |
| podSecurityContext | object | `{}` | pod security contect to add |
| db.database | string | `"netmaker"` | db name |
| db.password | string | `"password123"` | db password |
| postgres.enabled | bool | `true` | whether to deploy an in-cluster PostgreSQL instance |
| postgres.image.repository | string | `"postgres"` | PostgreSQL image repository |
| postgres.image.tag | string | `"18.0-bookworm"` | PostgreSQL image tag |
| postgres.storageSize | string | `"1Gi"` | size of PostgreSQL data volume |
| postgres.storageClassName | string | `""` | storage class for PostgreSQL PVC |
| postgres.resources | object | `{requests: {cpu: 250m, memory: 256Mi}, limits: {cpu: 1000m, memory: 512Mi}}` | CPU/memory requests and limits for PostgreSQL |
| server.RWX.storageClassName | string | `""` | storage class name of server PVC |
| server.storageSize | string | `"128Mi"` | storage  size of server volume |
| server.masterKey | string | `"netmaker"` | master key for netmaker server |
| server.replicas | int | `3` | number of netmaker server replicas to create |
| server.ee.licensekey | string | `""` | server license key required if using Enterprise version |
| server.ee.tenantId | string | `""` | tenantId of the license required if using Enterprise version |
| service.mqPort | int | `443` | public port for MQ service |
| db.type | string | `"postgres"` | type of db server connecting to supported types `"postgres"` `"sqlite"` `"rqlite"` |
| db.host | string | `""` | db host domain |
| db.port | int | `5432` | db port |
| db.username | string | `"postgres"` | db username |
| db.password | string | `"password123"` | db password |
| service.restPort | int | `8081` | port for API service |
| service.type | string | `"ClusterIP"` | type for netmaker server services |
| service.uiPort | int | `80` | port for UI service |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of SA to use. If not set and create is true, a name is generated using the fullname template |
| ui.replicas | int | `2` | how many UI replicas to create |

