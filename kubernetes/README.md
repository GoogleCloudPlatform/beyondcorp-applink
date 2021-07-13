# BCE Applink on Kubernetes

Deploy BCE Applink using Helm on Kubernetes.

## Prerequisites

* A running Kubernetes cluster. To launch a Kubernetes cluster using GKE, follow the [quickstart guide](https://cloud.google.com/kubernetes-engine/docs/quickstart).
* [kubectl](https://kubernetes.io/docs/tasks/tools/) and [helm](https://helm.sh/docs/intro/install/) installed.

## Instructions

* Download this folder.

* In a terminal, change directory to the newly downloaded folder.

* Edit the [`values.yaml`](values.yaml) file if desired.

* Run the script with appropriate arguments.

  * -c \[the Google Cloud Storage connection object returned from the output of the [Gateway](terraform-config.md#applink-gateway) step (gs://...)\]
  **Required**

  * -n \[Kubernetes namespace\]
  **Optional**

  * -s \[*service_account_email* from the [Connector](terraform-config.md#applink-connector) step\]
  **Required**

Example:
```
./helm-setup -c gs://921727625615-connector-c1/connections/apache -s connector-c1-sa@brettmeehan-applink.iam.gserviceaccount.com
```

## Cleanup
You can simply delete the Kubernetes namespace to destroy all allocated resources.

Example
```
kubectl delete namespace applink-k8s
```
