# Cloud Architecture Study

A hands‑on study project demonstrating a modern cloud‑native
architecture built around Kubernetes, Kafka, and full observability.

The system processes text messages asynchronously using an event‑driven
pipeline:

1.  A client sends text to an API.
2.  The API publishes the message to Kafka.
3.  A worker service consumes the message.
4.  The worker processes the text and outputs a result.

The platform includes:

-   containerized microservices
-   Kubernetes deployments
-   Kafka messaging
-   infrastructure as code
-   automated observability stack
-   cloud deployment on Azure

------------------------------------------------------------------------

# Architecture

## High‑Level Cloud Architecture

``` mermaid
flowchart LR

Client[Client / curl] --> LB[Azure Load Balancer]
LB --> Ingress[NGINX Ingress Controller]

Ingress --> ServiceAPI[Kubernetes Service: API]
ServiceAPI --> PodAPI[API Pod]

PodAPI --> Kafka[(Kafka Cluster)]

Kafka --> WorkerPod[Worker Pod]

Prometheus --> PodAPI
Prometheus --> WorkerPod
Prometheus --> Kafka

Promtail --> PodAPI
Promtail --> WorkerPod

Loki[Loki<br/>Log Aggregation]
Promtail --> Loki

Grafana --> Prometheus
Grafana --> Loki
```

This diagram shows the full request path from external client to the
internal application layer.

------------------------------------------------------------------------

## Kubernetes Internal Architecture

``` mermaid
flowchart LR

Ingress --> ServiceAPI
ServiceAPI --> API_Pod1
ServiceAPI --> API_Pod2

API_Pod1 --> Kafka
API_Pod2 --> Kafka

Kafka --> Worker1
Kafka --> Worker2

Prometheus[Prometheus]
Prometheus --> API_Pod1
Prometheus --> API_Pod2
Prometheus --> Worker1
Prometheus --> Worker2

Promtail[Promtail<br/>Log Collector]
Promtail --> API_Pod1
Promtail --> API_Pod2
Promtail --> Worker1
Promtail --> Worker2

Loki[Loki<br/>Log Aggregation]
Promtail --> Loki

Grafana[Grafana]
Grafana --> Prometheus
Grafana --> Loki
```

This illustrates how services and pods interact internally inside
Kubernetes.

------------------------------------------------------------------------

## Message Processing Flow

``` mermaid
sequenceDiagram

participant Client
participant API
participant Kafka
participant Worker
participant Promtail
participant Loki

Client->>API: POST /job
API->>Kafka: publish message
API->>Promtail: emit logs
Kafka->>Worker: deliver message
Worker->>Worker: process text
Worker->>Promtail: emit logs
Promtail->>Loki: ship logs
Worker-->>Logs: output result
```

------------------------------------------------------------------------

# Tech Stack

| Layer            | Technology                 |
|------------------|----------------------------|
| Runtime          | Node.js                    |
| Containerization | Docker                     |
| Orchestration    | Kubernetes                 |
| Messaging        | Apache Kafka               |
| Kafka Operator   | Strimzi                    |
| Metrics          | Prometheus                 |
| Logging          | Loki + Promtail            |
| Dashboards       | Grafana                    |
| Ingress          | NGINX Ingress Controller   |
| Infrastructure   | Terraform                  |
| Cloud            | Azure Kubernetes Service   |

------------------------------------------------------------------------

# System Flow

1.  Client sends text to API.
2.  API publishes message to Kafka.
3.  Worker consumes message from Kafka.
4.  Worker processes the text payload and logs results.
5.  Promtail collects logs from all services.
6.  Logs are aggregated in Loki.
7.  Metrics are exposed to Prometheus.
8.  Grafana dashboards visualize system metrics and logs.

------------------------------------------------------------------------

# Infrastructure

Infrastructure is provisioned using Terraform.

Main components:

-   Azure Kubernetes Service cluster
-   Kafka cluster managed by Strimzi
-   NGINX Ingress controller
-   Prometheus metrics collection
-   Loki log aggregation
-   Grafana dashboards for metrics and logs

------------------------------------------------------------------------

# Observability

## Metrics

Metrics can be visualized both in Grafana and Prometheus.

The system exposes metrics from:

-   API service
-   worker service
-   Kubernetes infrastructure
-   Kafka consumer lag

Dashboards include:

-   API pod count
-   Worker pod count
-   Infrastructure pod count
-   CPU usage
-   Memory usage
-   Kafka consumer lag

## Logging

Logs are collected and aggregated using **Loki** and **Promtail**:

-   **Promtail** - Agent that collects logs from pods and ships them to Loki
-   **Loki** - Log aggregation system integrated with Grafana
-   Logs from API and Worker services are automatically collected
-   Query and visualize logs alongside metrics in Grafana dashboards

------------------------------------------------------------------------

# Running Locally

Requirements:

-   Docker
-   Kubernetes
-   kubectl
-   Helm

Prepare the local environment:

``` bash
./scripts/environments/local/cluster-bootstrap.sh
```

Deploy services locally:

``` bash
./scripts/environments/local/deploy.sh
```

For a simpler approach, you can also use Docker Compose:

```bash
./scripts/environments/local/dev-up.sh # dev-down.sh to stop
```

Send a test request:

``` bash
curl http://<MINIKUBE SERVICE URL>/job \
  -H "Content-Type: application/json" \
  -d '{"text":"hello kafka kubernetes"}'
```

------------------------------------------------------------------------

# Deploying to Azure

Having the credentials configured (`az login`), provision the infrastructure:

``` bash
cd terraform/environments/cloud
terraform init
terraform apply
```

Install the necessary technologies in the cluster:

```bash
./scripts/general/install-ingress.sh
./scripts/general/install-observability.sh    # Prometheus, Grafana, Loki, Promtail
./scripts/general/install-strimzi.sh
```

Deploy services:

``` bash
./scripts/environments/azure/deploy.sh
```

------------------------------------------------------------------------

# Project Structure

    .
    ├── docker/                 # Local docker compose setup
    ├── docs/                   # Architecture documentation
    ├── k8s/                    # Kubernetes manifests
    │   ├── api/
    │   ├── worker/
    │   ├── kafka/
    │   ├── observability/
    │   ├── reliability/
    │   └── apps/
    ├── scripts/
    │   ├── environments/
    │   │   ├── local/          # Local development scripts
    │   │   └── azure/          # Cloud deployment scripts
    │   └── general/            # Shared scripts (both local and cloud)
    ├── services/               # Application source code
    │   ├── api/
    │   └── worker/
    └── terraform/              # Infrastructure as Code
        ├── environments/
        └── modules/

------------------------------------------------------------------------

# Example Request

``` bash
curl http://<INGRESS IP>/job \
  -H "Host: api.local" \
  -H "Content-Type: application/json" \
  -d '{"text":"hello kafka kubernetes hello"}'
```

The API responds with:

``` json
{
  "status": "queued",
  "message": {
    "text": "hello kafka kubernetes hello",
    "timestamp": "2024-03-16T02:00:00.000Z"
  }
}
```

The worker processes the message and logs the result (word frequency analysis):

``` json
{
  "hello": 2,
  "kafka": 1,
  "kubernetes": 1
}
```

View the logs in Grafana to see the processing results.

------------------------------------------------------------------------

# Future Improvements

Planned improvements for future iterations:

-   Dead Letter Queue (DLQ)
-   Horizontal Pod Autoscaling
-   Kafka‑based autoscaling
-   CI/CD pipeline
-   Distributed tracing
