# Netmaker Helm

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.21.2](https://img.shields.io/badge/AppVersion-0.21.2-informational?style=flat-square)

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

Furthermore, the chart will by default install and use a postgresql cluster as its datastore: 

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql-ha | 7.11.0 |

### Example Install

```
helm repo add netmaker https://gravitl.github.io/netmaker-helm/
helm install netmaker/netmaker --generate-name \ # generate a random id for the deploy 
--set baseDomain=nm.example.com \ # the base wildcard domain to use for the netmaker api/dashboard/mq ingress 
--set server.replicas=3 \ # number of server replicas to deploy (3 by default) 
--set ingress.enabled=true \ # deploy ingress automatically (requires nginx and cert-manager + letsencrypt) 
--set ingress.kubernetes.io/ingress.class=nginx \ # ingress class to use
--set ingress.cert-manager.io/cluster-issuer=letsencrypt-prod \ # LetsEncrypt certificate issuer to use
--set postgresql-ha.postgresql.replicaCount=2 \ # number of DB replicas to deploy (default 2)
```

### Recommended Settings:

This install has some notable exceptions:
- Ingress **must** be configured on your cluster, with cluster issuer for TLS certs
- DNS will be disabled

Below, we discuss the considerations for Ingress, Kernel WireGuard, and DNS.

#### MQ

The MQ Broker is deployed either with Ingress (Nginx ) preconfigured, or without. If you are using an ingress controller other than Nginx, Netmaker's MQTT will not be complete. "broker.domain"  must reach the MQTT service at port 8883 over WSS (Secure Web Sockets).

#### Ingress	
To run HA Netmaker, you must have ingress installed and enabled on your cluster with valid TLS certificates (not self-signed). If you are running Nginx as your Ingress Controller and LetsEncrypt for TLS certificate management, you can run the helm install with the following settings:
`--set ingress.enabled=true`
`--set ingress.annotations.cert-manager.io/cluster-issuer=<your LE issuer name>`

If you are not using Nginx and LetsEncrypt, we recommend leaving ingress.enabled=false (default), and then manually creating the ingress objects post-install. You will need three ingress objects with TLS:
`dashboard.<baseDomain>`
`api.<baseDomain>`
`broker.<baseDomain>`

You can find example ingress objects in the kube/example folder.

#### DNS
By Default, the helm chart will deploy without DNS enabled. To enable DNS, specify with:
`--set dns.enabled=true` 
This will require specifying a RWX storage class, e.g.:
`--set dns.RWX.storageClassName=nfs`
This will also require specifying a service address for DNS. Choose a valid ipv4 address from the service IP CIDR for your cluster, e.g.:
`--set dns.clusterIP=10.245.69.69`

**This address will only be reachable from hosts that have access to the cluster service CIDR.** It is only designed for use cases related to k8s. If you want a more general-use Netmaker server on Kubernetes for use cases outside of k8s, you will need to do one of the following:
- bind the CoreDNS service to port 53 on one of your worker nodes and set the COREDNS_ADDRESS equal to the public IP of the worker node
- Create a private Network with Netmaker and set the COREDNS_ADDRESS equal to the private address of the host running CoreDNS. For this, CoreDNS will need a node selector and will ideally run on the same host as one of the Netmaker server instances.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dns.enabled | bool | `false` | whether or not to run with DNS (CoreDNS) |
| dns.storageSize | string | `"128Mi"` | volume size for DNS (only needs to hold one file) |
| fullnameOverride | string | `""` | override the full name for netmaker objects  |
| image.pullPolicy | string | `"Always"` | Pull Policy for images |
| image.repository | string | `"gravitl/netmaker"` | The image repo to pull Netmaker image from  |
| image.tag | string | `"latest"` | Override the image tag to pull  |
| ingress.annotations."kubernetes.io/ingress.class" | string | `"nginx"` | ingress class name |
| ingress.annotations."cert-manager.io/cluster-issuer" | string | `"letsencrypt-prod"` | cert manager cluster issuer name |
| ingress.enabled | bool | `false` | attempts to configure ingress if true |
| ingress.hostPrefix.mq | string | `"broker"` | broker route subdomain |
| ingress.hostPrefix.rest | string | `"api"` | api (REST) route subdomain |
| ingress.hostPrefix.ui | string | `"dashboard"` | ui route subdomain |
| ingress.tls | bool | `true` |  |
| nameOverride | string | `""` | override the name for netmaker objects  |
| podAnnotations | object | `{}` | pod annotations to add |
| podSecurityContext | object | `{}` | pod security contect to add |
| postgresql-ha.persistence.size | string | `"3Gi"` | size of postgres DB |
| postgresql-ha.postgresql.database | string | `"netmaker"` | postgress db to generate |
| postgresql-ha.postgresql.password | string | `"password123"` | postgres pass to generate |
| postgresql-ha.postgresql.username | string | `"netmaker"` | postgres user to generate |
| server.RWX.storageClassName | string | `""` | storage class name of server PVC |
| server.storageSize | string | `"128Mi"` | storage  size of server volume |
| server.masterKey | string | `"netmaker"` | master key for netmaker server |
| server.replicas | int | `3` | number of netmaker server replicas to create |
| server.ee.licenseKey | string | `""` | server license key required if using Enterprise version |
| server.ee.tenantId | string | `""` | tenantId of the license required if using Enterprise version |
| service.mqPort | int | `443` | public port for MQ service |
| db.type | string | `"postgres"` | type of db server connecting to supported types `"postgres"` `"sqlite"` `"rqlite"` |
| db.host | string | `""` | db host domain |
| db.port | int | `5432` | db port |
| db.username | string | `"postgres"` | db username |
| db.password | string | `"password123"` | db password |
| db.database | string | `"netmaker"` | db password |
| service.restPort | int | `8081` | port for API service |
| service.type | string | `"ClusterIP"` | type for netmaker server services |
| service.uiPort | int | `80` | port for UI service |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | Name of SA to use. If not set and create is true, a name is generated using the fullname template |
| ui.replicas | int | `2` | how many UI replicas to create |

