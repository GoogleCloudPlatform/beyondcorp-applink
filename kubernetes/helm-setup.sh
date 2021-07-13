#!/bin/bash
#
## Copyright 2021 Google LLC
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
#
#
# Sets up Kubernetes resources to be used with Helm.

set -euox pipefail

function usage () {
  cat << USAGE
  Set up the dynamic Kubernetes resources for the Helm Chart
  Usage: $0 -s <service_account> -c <connection_gcs_uri> -n <kubernetes_namespace>

  -c <connections_gcs_uri>  The Google Cloud Storage URI for the connection
                            file object (gs://bucket-name/object-name)
  -h                        Print this help message.
  -n <kubernetes_namespace> The Kubernetes namespace to hold resources.
  -s <service_account>      The email of the service account to be
                            impersonated
                            (sa-name@project-id.iam.gserviceaccount.com)

USAGE
}

GCS_CONNECTION_OBJECT_ID=''
SERVICE_ACCOUNT=''
KUBERNETES_NAMESPACE='applink-k8s'
readonly KUBERNETES_CM_NAME='connections'
readonly KUBERNETES_SECRET_NAME='credentials'

# Parse command-line flags
while getopts 'c:hn:s:' opt; do
  case "${opt}" in
    c) GCS_CONNECTION_OBJECT_ID="${OPTARG}" ;;
    h)
      usage
      exit 0
      ;;
    n) KUBERNETES_NAMESPACE="${OPTARG}" ;;
    s) SERVICE_ACCOUNT="${OPTARG}" ;;
    ?)
      usage >&2
      exit 1
      ;;
      esac
done

# Make sure GCS_CONNECTION_OBJECT_ID was set and has valid format
if [[ ! "${GCS_CONNECTION_OBJECT_ID}" =~ ^gs:// ]]; then
  echo 'Invalid GCS URI format for <connection_gcs_uri>' >&2
  usage >&2
  exit 1
fi

# Perform a service account email format check
readonly GCP_ID_REGEX='[a-z][-a-z0-9]{4,28}[a-z0-9]'
readonly SERVICE_ACCT_EMAIL_REGEX="^${GCP_ID_REGEX}@${GCP_ID_REGEX}\.iam\.gserviceaccount\.com$"
if [[ -z "${SERVICE_ACCOUNT}" ]] ||
   [[ ! "${SERVICE_ACCOUNT}" =~ ${SERVICE_ACCT_EMAIL_REGEX} ]]; then
  echo 'Invalid email format for <service_account>' >&2
  usage >&2
  exit 1
fi

readonly GCS_CONNECTION_OBJECT_ID
readonly SERVICE_ACCOUNT

# Cleanup any previous ConfigMaps and Secrets
kubectl delete cm "${KUBERNETES_CM_NAME}" --namespace="${KUBERNETES_NAMESPACE}" || true
kubectl delete secret "${KUBERNETES_SECRET_NAME}" --namespace="${KUBERNETES_NAMESPACE}" || true

# Create the Kubernetes namespace if it doesn't exist
echo -e "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: ${KUBERNETES_NAMESPACE}" |
kubectl apply -f -

# Create a directory for storing Applink connections.
# This will be shared as a Kubernetes ConfigMap
if [[ ! -d /etc/applink/connections ]]; then
  sudo mkdir -p /etc/applink/connections
fi

# Use gsutil to fetch the connection configuration file from GCS and move it
# into the Applink configurations directory
mkdir -p connections
gsutil cp "${GCS_CONNECTION_OBJECT_ID}" ./connections/
sudo mv ./connections/* /etc/applink/connections


# Create the connections ConfigMap
kubectl create cm "${KUBERNETES_CM_NAME}" --namespace="${KUBERNETES_NAMESPACE}" --from-file=/etc/applink/connections/

readonly SERVICE_ACCOUNT_KEY="${HOME}/.config/gcloud/${SERVICE_ACCOUNT}-key.json"
# Check if a service account key already exists
# If not, create one
if [[ ! -f "${SERVICE_ACCOUNT_KEY}" ]]; then
  gcloud iam service-accounts keys create "${SERVICE_ACCOUNT_KEY}" \
  --iam-account="${SERVICE_ACCOUNT}"
fi

# Create the credentials Secret
kubectl create secret generic "${KUBERNETES_SECRET_NAME}" --from-file=key.json="${SERVICE_ACCOUNT_KEY}" --namespace="${KUBERNETES_NAMESPACE}"
