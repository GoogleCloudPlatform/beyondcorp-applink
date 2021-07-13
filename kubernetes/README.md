# BCE Applink on Kubernetes

Deploy BCE Applink on Kubernetes.

The setup relies on Helm to deploy the application to Kubernetes.

## Prerequisites

* A running Kubernetes cluster. To launch a Kubernetes cluster using GKE, follow the [quickstart guide](https://cloud.google.com/kubernetes-engine/docs/quickstart).
* [kubectl](https://kubernetes.io/docs/tasks/tools/) and [helm](https://helm.sh/docs/intro/install/) installed.

## Instructions

* Download this folder.

* In a terminal, change directory to the newly downloaded folder.

* Edit the [`values.yaml`](values.yaml) file if desired.

* Install the Helm chart through the helper script.

  * -c \[the Google Cloud Storage connection object returned from the output of the [Gateway](terraform-config.md#applink-gateway) step (gs://...)\]
  **Required**

  * -n \[Kubernetes namespace\]
  **Optional**

  * -s \[*service_account_email* from the [Connector](terraform-config.md#applink-connector) step\]
  **Required**

Example:
```
./helm-setup.sh -c gs://921727625615-connector-c1/connections/apache -s connector-c1-sa@brettmeehan-applink.iam.gserviceaccount.com
```

## Inspecting the Cluster
Below are some commands that you may find helpful when debugging the application:

```bash
# Cluster Information
kubectl cluster-info

# Get Secrets
kubectl get secrets --namespace=applink-k8s
# List ConfigMaps
kubectl get cm --namespace=applink-k8s
# Inspect a ConfigMap
kubectl describe cm <cm_name> --namespace=applink-k8s

# List Deployments
kubectl get deployment --namespace=applink-k8s
# Get Pods
kubectl get pods --namespace=applink-k8s
# Check logs of a pod
kubectl logs <pod_name> --namespace=applink-k8s

# View the Connections CR
kubectl describe connections.applink.tutorial.kubebuilder.io connections-sample --namespace=applink-k8s
```

## Cleanup
You can simply delete the Kubernetes namespace to destroy all allocated resources.

Example
```
kubectl delete namespace applink-k8s
```

[Next: Publish application using Identity Aware Proxy](iap-lb-setup.md)
