#!/bin/bash

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

export CLOUDSDK_CORE_DISABLE_PROMPTS=1

readonly RED="$(tput setaf 1)"
readonly GREEN="$(tput setaf 2)"
readonly YELLOW="$(tput setaf 3)"
readonly MAGENTA="$(tput setaf 5)"
readonly CYAN="$(tput setaf 6)"
readonly BOLD="$(tput bold)"
readonly RESET="$(tput sgr0)"

readonly RESOURCE=$1
readonly OP=$2
readonly NAME=$3

usage_network() {
  cat <<USAGE

    network create <NAME> -r <REGION> -p <PROJECT_ID>  Creates a new network in the consumer
                                                       VPC with NAME in REGION and with the
                                                       consumer project specified by PROJECT_ID.
                                                       Currently only one network is supported
                                                       at a time. You must delete the existing
                                                       network before a new one can be created.

    network delete                                     Deletes the existing network.

    network list                                       Displays info on the existing network.

USAGE
}

usage_connectors() {
  cat <<USAGE

    connectors create <NAME>                           Creates a new connector with NAME.

    connectors delete <NAME>                           Deletes a connector with NAME.

    connectors describe <NAME>                         Describes a connector with NAME.

    connectors list                                    Lists all existing connectors.

USAGE
}

usage_connections() {
  cat <<USAGE

    connections create <NAME> -c <CONNECTOR_NAME,...> -h <APP_HOST> -p <APP_PORT>

                                                       Creates a new connection with NAME that
                                                       uses the specified connectors. Connectors
                                                       are a comma-separated list. APP_HOST and
                                                       APP_PORT specify the location of the
                                                       on-prem application.

    connections delete <NAME>                          Deletes a connection with NAME.

    connections describe <NAME>                        Describes a connection with NAME.

    connections list                                   Lists all existing connections.

USAGE
}

usage_app() {
  cat <<USAGE

    app publish <CONNECTION_NAME> -f <http|https> -b <http|https> [optional_flags]

                                                       Publishes a connection and make the
                                                       on-prem application reachable via the
                                                       internet under the protection of
                                                       BeyondCorp AppConnector.

      -f <http|https>                                  Protocol of the frontend load balancer.

      -b <http|https>                                  Protocol of the backend server.

      -d <domain>                                      Domain name via which to reach the
                                                       application (requires DNS setup).
                                                       This is required if the frontend protocol
                                                       is https, ignored otherwise.

      -i <IPv4_address>                                IP address via which to reach the
                                                       application. This is only used if the
                                                       frontend protocol is http. In the case
                                                       of https, it is inferred from the domain.
                                                       If not specified, one will be provisioned
                                                       for you at runtime.

      -e                                               If set, IAP will be enabled for your app.

      -g <comma_separated_groups>                      A list of comma-separated groups to
                                                       grant permission to for accessing
                                                       the application. E.g. admins@domain.com
                                                       Only used if IAP is enabled.

      -u <comma_separated_users>                       A list of comma-separated users to
                                                       grant permission to for accessing
                                                       the application. E.g. user@gmail.com
                                                       Only used if IAP is enabled.


    app unpublish <CONNECTION_NAME> -f <http|https>    Unpublishes the connection. The frontend
                                                       protocol with which the connection was
                                                       originally published needs to be specified.

USAGE
}

usage() {
  less -R <<USAGE

  ${BOLD}Usage: $0 <RESOURCE> <OPERATION> <NAME> [flags]

  ${BOLD}Network
  $(usage_network)

  ${BOLD}Connectors
  $(usage_connectors)

  ${BOLD}Connections
  $(usage_connections)

  ${BOLD}App
  $(usage_app)
USAGE
}

error() {
  echo -n "${RED}${BOLD}ERROR: ${RESET}"
}

success() {
  echo -n "${GREEN}${BOLD}SUCCESS: ${RESET}"
}

info() {
  echo -n "${CYAN}${BOLD}INFO: ${RESET}"
}

warn() {
  echo -n "${YELLOW}${BOLD}WARNING: ${RESET}"
}

verify_name() {
  if [[ -z $NAME ]] || [[ $NAME == -* ]]; then
    if [[ $NAME == "-h" ]] || [[ $NAME == "--help" ]]; then
      usage
      exit
    fi
    error && echo "Missing argument: <NAME>"
    exit 1
  fi
}

verify_no_name() {
  if [[ -n $NAME ]]; then
    error && echo "Unrecognized argument: $NAME"
    exit 1
  fi
}

verify_no_extraneous_arguments() {
  shift "$((OPTIND - 1))"
  [[ "$#" -eq 0 ]] || {
    error && echo "Unrecognized argument: ${1}"
    exit 1
  }
}

oauth_brand_instructions() {
  cat <<EOM

${MAGENTA}${BOLD}You need a Cloud OAuth brand for the project and you currently do not have one set up.${RESET}

${YELLOW}You can set it up in the Cloud Console at https://console.cloud.google.com/apis/credentials/consent.
Make sure to select the project you are running this CLI with.

Alternatively, you can run the following command to set it up:
$ gcloud alpha iap oauth-brands create --application_title=<APPLICATION_TITLE> --support_email=<SUPPORT_EMAIL>
See https://cloud.google.com/sdk/gcloud/reference/alpha/iap/oauth-brands/create for details.

EOM
}

check_dependency() {
  # check existence.
  local name="${1}"
  local install_error_message="The BeyondCorp CLI requires ${BOLD}${name}${RESET} to function, ${2}"
  if ! command -v "${name}" &>/dev/null; then
    error && echo "${install_error_message}"
    exit 1
  fi
  if [[ "${#}" -eq 2 ]]; then
    return 0
  fi
  # check version.
  local minimum_version="${3}"
  local version_pattern="${4}"
  local update_error_message="The BeyondCorp CLI requires version of ${BOLD}${name} >= ${minimum_version}${RESET}, ${5}"
  local current_version
  if ! current_version="$("${name}" --version 2> /dev/null)"; then
    error && echo "failed to get the version of ${name}"
    exit 1
  fi
  local current
  current="$(echo "${current_version}" | grep -oP "${version_pattern}")"
  if [[ "$(printf '%s\n' "${minimum_version}" "${current}" | sort -V | head -n1)" != "${minimum_version}" ]]; then
    error && echo "${update_error_message}"
    exit 1
  fi
}

check_dependencies() {
  check_dependency "gcloud" "please see https://cloud.google.com/sdk/docs/install for installation." \
    "363.0.0" "Google Cloud SDK \K.+" "please see https://cloud.google.com/sdk/gcloud/reference/components/update for update."
  check_dependency "jq" "please see https://stedolan.github.io/jq/download/ for installation."
  check_dependency "dig" "make sure to install it before using the CLI."
}

init() {
  set -e
  gcloud config set project "$1"
  info && echo "Checking if all necessary APIs are enabled for your project...We will automatically enable any that are not."
  gcloud services enable compute.googleapis.com
  gcloud services enable beyondcorp.googleapis.com
  gcloud services enable iap.googleapis.com
  gcloud services enable cloudresourcemanager.googleapis.com
  gcloud services enable deploymentmanager.googleapis.com
  set +e
}

network_create() {
  init "$3"
  local network_name="${1}"
  NETWORK_NAME=${network_name}-network
  SUBNET_NAME=${network_name}-subnet
  {
    echo "network=${NETWORK_NAME}"
    echo "subnet=${SUBNET_NAME}"
    echo "region=$2"
    echo "project=$3"
  } >"$HOME/bce_network_settings"

  REGION=$2
  PROJECT_ID=$3

  template="*nat
:PREROUTING ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
{{ range tree \"beyondcorp/port_mapping\" }}
-A PREROUTING -p tcp -m tcp --dport {{ .Key }} -j DNAT --to-destination {{ .Value }}:19443{{ end }}
-A POSTROUTING -j MASQUERADE
COMMIT
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT"

  startup="sudo apt-get install consul
  curl https://releases.hashicorp.com/consul-template/0.27.0/consul-template_0.27.0_linux_amd64.zip --output consul-template_0.27.0_linux_amd64.zip
  sudo apt-get install unzip
  sudo unzip consul-template_0.27.0_linux_amd64.zip -d /usr/local/bin/
  sudo chmod 0755 /usr/local/bin/consul-template
  sudo mkdir /var/beyondcorp
  echo '${template}' > /var/beyondcorp/iptables.tpl
  consul agent -dev &
  consul-template -template \"/var/beyondcorp/iptables.tpl:/var/beyondcorp/iptables.txt:sudo iptables-restore < /var/beyondcorp/iptables.txt\" &"

  gcloud compute networks create "${NETWORK_NAME}" --subnet-mode=custom
  gcloud compute networks subnets create "${SUBNET_NAME}" --network="${NETWORK_NAME}" --range=10.9.2.0/24 --region="${REGION}"
  gcloud compute instances create nat-vm-"${SUBNET_NAME}" --zone="${REGION}"-a --image-family=debian-10 --image-project=debian-cloud --subnet="${SUBNET_NAME}" --metadata=startup-script="$startup"
  gcloud compute instances create nat-vm-"${SUBNET_NAME}"-ha --zone="${REGION}"-a --image-family=debian-10 --image-project=debian-cloud --subnet="${SUBNET_NAME}" --metadata=startup-script="$startup"
  gcloud compute firewall-rules create "${SUBNET_NAME}"-fw-allow --network "${NETWORK_NAME}" --allow tcp,udp,icmp --source-ranges 35.191.0.0/16,35.235.240.0/20
  # we need to wait for the VM instance to show up
  vm_reachable="false"
  num_retries=10
  sleep_intvl=5
  while [[ "$vm_reachable" == "false" ]]; do
    ready=$(gcloud compute ssh --command 'echo ready' "nat-vm-${SUBNET_NAME}" --zone "${REGION}" 2>&1 | grep ready)
    ready2=$(gcloud compute ssh --command 'echo ready' "nat-vm-${SUBNET_NAME}"-ha --zone "${REGION}" 2>&1 | grep ready)
    if [[ "$ready" == "ready" ]] && [[ "$ready2" == "ready" ]]; then
      vm_reachable="true"
      success && echo "VMs are ready"
    else
      info && echo "Waiting for the VMs to be reachable via IAP TCP....sleep for $sleep_intvl sec"
      sleep $sleep_intvl
      num_retries=$((num_retries - 1))
      if [[ $num_retries -eq 0 ]]; then
        break
      fi
    fi
  done
  gcloud compute instances delete-access-config nat-vm-"${SUBNET_NAME}" --zone="${REGION}"-a
  gcloud compute instances delete-access-config nat-vm-"${SUBNET_NAME}"-ha --zone="${REGION}"-a
  gcloud compute ssh --command='sudo sysctl net.ipv4.ip_forward=1' "nat-vm-${SUBNET_NAME}" --zone="${REGION}-a"
  gcloud compute ssh --command='sudo sysctl net.ipv4.ip_forward=1' "nat-vm-${SUBNET_NAME}"-ha --zone="${REGION}-a"
  gcloud compute instance-groups unmanaged create "nat-vm-${SUBNET_NAME}-ig" --zone "${REGION}-a"
  gcloud compute instance-groups unmanaged add-instances "nat-vm-${SUBNET_NAME}-ig" --instances "nat-vm-${SUBNET_NAME}" --zone "${REGION}-a"
  gcloud compute instance-groups unmanaged add-instances "nat-vm-${SUBNET_NAME}-ig" --instances "nat-vm-${SUBNET_NAME}"-ha --zone "${REGION}-a"

  iap_oauth_brand=$(gcloud alpha iap oauth-brands list --format="value(name)")
  if [[ -z "$iap_oauth_brand" ]]; then
    oauth_brand_instructions
  fi
}

network_delete() {
  if [[ -f "$HOME/bce_network_settings" ]]; then
    gcloud compute instance-groups unmanaged delete "nat-vm-${SUBNET_NAME}-ig" --zone="${REGION}-a"
    gcloud compute instances delete "nat-vm-${SUBNET_NAME}" --zone="${REGION}-a"
    gcloud compute instances delete "nat-vm-${SUBNET_NAME}"-ha --zone="${REGION}-a"
    gcloud compute firewall-rules delete "${SUBNET_NAME}-fw-allow"
    gcloud compute networks subnets delete "${SUBNET_NAME}" --region="${REGION}"
    gcloud compute networks delete "${NETWORK_NAME}"
    rm "$HOME/bce_network_settings"
    return
  fi
  error && echo "${HOME}/bce_network_settings cannot be found"
}

network_list() {
  if [[ -f "$HOME/bce_network_settings" ]]; then
    cat "${HOME}/bce_network_settings"
    return
  fi
  error && echo "${HOME}/bce_network_settings cannot be found"
}

check_network() {
  if ! [[ -f "$HOME/bce_network_settings" ]]; then
    error && echo "You need to first create a network to perform this action."
    exit 1
  fi
}

connectors_create() {
  check_network
  local connector_name="${1}"
  local member="serviceAccount:${connector_name}@${PROJECT_ID}.iam.gserviceaccount.com"
  gcloud iam service-accounts create "${connector_name}"
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "${member}" \
    --role roles/beyondcorp.connectionAgent
  gcloud alpha beyondcorp app connectors create "${connector_name}" \
    --project "${PROJECT_ID}" \
    --location "${REGION}" \
    --member "${member}" \
    --display-name "${connector_name}"
  cat <<EOM

${MAGENTA}${BOLD}Log in to the connector remote agent VM and run the following commands:${RESET}

${YELLOW}$ curl https://raw.githubusercontent.com/GoogleCloudPlatform/beyondcorp-applink/main/bash-scripts/install-beyondcorp-runtime -o ./install-beyondcorp-runtime && chmod +x ./install-beyondcorp-runtime && ./install-beyondcorp-runtime

$ bce-connctl config set project ${PROJECT_ID}
  bce-connctl config set region ${REGION}
  bce-connctl config set connector ${connector_name}
  bce-connctl enrollment create${RESET}

EOM
}

connectors_delete() {
  check_network
  local connector_name="${1}"
  local service_account="${connector_name}@${PROJECT_ID}.iam.gserviceaccount.com"
  gcloud projects remove-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${service_account}" \
    --role roles/beyondcorp.connectionAgent
  gcloud alpha beyondcorp app connectors delete "${connector_name}" \
    --project "${PROJECT_ID}" \
    --location "${REGION}"
  gcloud iam service-accounts delete "${service_account}"
}

connectors_describe() {
  check_network
  local connector_name="${1}"
  gcloud alpha beyondcorp app connectors describe "${connector_name}" \
    --project "${PROJECT_ID}" \
    --location "${REGION}" | jq
}

connectors_list() {
  check_network
  gcloud alpha beyondcorp app connectors list \
    --project "${PROJECT_ID}" \
    --location "${REGION}"
}

connections_create() {
  check_network
  local connection_name="${1}"
  local connector_names="${2}"
  local app_host="${3}"
  local app_port="${4}"
  gcloud alpha beyondcorp app connections create "${connection_name}" \
    --project "${PROJECT_ID}" \
    --location "${REGION}" \
    --application-endpoint "${app_host}:${app_port}" \
    --type "tcp" \
    --connectors "${connector_names}" \
    --display-name "${connection_name}"

  gw_uri="$(connections_describe "${connection_name}" | jq -r .gateway.uri)"
  success && echo "Created connection: PSC Service Attachment  ${gw_uri}"
  info && echo "Attaching to the consumer VPC...."
  gcloud compute addresses create "${connection_name}-vip" --region="${REGION}" --subnet="${SUBNET_NAME}"
  gcloud beta compute forwarding-rules create "${connection_name}-psc-fr" --region="${REGION}" --network="${NETWORK_NAME}" --address="${connection_name}-vip" --target-service-attachment="${gw_uri}"
}

connections_delete() {
  check_network
  local connection_name="${1}"
  gcloud alpha beyondcorp app connections delete "${connection_name}" \
    --project "${PROJECT_ID}" \
    --location "${REGION}"
  gcloud beta compute forwarding-rules delete "${connection_name}-psc-fr" --region="${REGION}"
  gcloud compute addresses delete "${connection_name}-vip" --region="${REGION}"
}

connections_describe() {
  check_network
  local connection_name="${1}"
  gcloud alpha beyondcorp app connections describe "${connection_name}" \
    --project="${PROJECT_ID}" \
    --location="${REGION}" | jq
}

connections_list() {
  check_network
  gcloud alpha beyondcorp app connections list \
    --project="${PROJECT_ID}" \
    --location="${REGION}"
}

port_alloc() {
  network_file=${HOME}/bce_network_settings_port
  start_port=20000
  local port=20000
  if [[ ! -f "$network_file" ]]; then
    echo "$start_port" >"$network_file"
  fi
  port=$(cat "$network_file")
  next_port="$((port + 1))"
  echo "$next_port" >"$network_file"
  echo "$port"
}

publish_app() {
  check_network
  local connection_name="${1}"
  local frontend_protocol="${2}"
  local backend_protocol="${3}"
  local domain="${4}"
  local xlb_vip_addr="${5}"
  local iap="${6}"
  local groups="${7}"
  local users="${8}"
  operation=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" "https://beyondcorp.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/${REGION}/connections/${connection_name}" | jq -r .error.status)
  if [[ ${operation} == "NOT_FOUND" ]]; then
    error && echo "Connection ${connection_name} was not found."
    return 1
  fi
  fr_name="${connection_name}-psc-fr"
  ipaddr=$(gcloud compute forwarding-rules describe "${fr_name}" --region="${REGION}" | grep IPAddress | awk '{print $2}')
  beport=$(port_alloc)
  gcloud compute ssh --command="consul kv put beyondcorp/port_mapping/${beport} ${ipaddr} && consul kv put beyondcorp/connection_mapping/${connection_name} ${beport}" nat-vm-"${SUBNET_NAME}" --zone "${REGION}"-a
  gcloud compute ssh --command="consul kv put beyondcorp/port_mapping/${beport} ${ipaddr} && consul kv put beyondcorp/connection_mapping/${connection_name} ${beport}" nat-vm-"${SUBNET_NAME}"-ha --zone "${REGION}"-a
  gcloud compute instance-groups unmanaged set-named-ports "nat-vm-${SUBNET_NAME}-ig" --named-ports="${fr_name}:${beport}" --zone "${REGION}-a"
  gcloud compute health-checks create tcp "${connection_name}-hc" --port="${beport}"
  gcloud compute backend-services create "${connection_name}-be" --health-checks "${connection_name}-hc" --global --port-name="${fr_name}" --protocol="${backend_protocol}"
  gcloud compute backend-services add-backend "${connection_name}-be" --instance-group nat-vm-"${SUBNET_NAME}-ig" --instance-group-zone "${REGION}-a" --global
  gcloud compute url-maps create "${connection_name}-map" --default-service "${connection_name}-be"

  if [[ "$frontend_protocol" == "https" ]]; then
    xlb_vip_addr=$(dig +short "${domain}")
    gcloud compute ssl-certificates create "${connection_name}-cert" --domains="${domain}" --global
    gcloud compute target-https-proxies create "${connection_name}-lb" --ssl-certificates "${connection_name}-cert" --global-ssl-certificates --global --url-map "${connection_name}-map"
    gcloud compute forwarding-rules create "${connection_name}-xlb-fwdrule" --address "$xlb_vip_addr" --global --target-https-proxy="${connection_name}-lb" --ports=443
  else
    if [[ -z "${xlb_vip_addr}" ]]; then
      gcloud compute addresses create "${connection_name}-xlb-vip" --ip-version=IPV4 --global
      xlb_vip_addr="${connection_name}-xlb-vip"
      ip=$(gcloud compute addresses describe "${connection_name}-xlb-vip" --global --format=json | jq -r .address)
      success && echo "The external IP ${ip} was generated for your app."
    fi
    gcloud compute target-http-proxies create "${connection_name}-lb" --global --url-map "${connection_name}-map"
    gcloud compute forwarding-rules create "${connection_name}-xlb-fwdrule" --address "$xlb_vip_addr" --global --target-http-proxy="${connection_name}-lb" --ports=80
  fi

  if [[ "${iap}" == true ]]; then
    iap_oauth_brand=$(gcloud alpha iap oauth-brands list --format="value(name)")
    if [[ -z "$iap_oauth_brand" ]]; then
      oauth_brand_instructions
      return 1
    fi
    iap_oauth_client=$(gcloud alpha iap oauth-clients create "$iap_oauth_brand" --display_name="$connection_name" --format=json)
    client_id=$(echo "$iap_oauth_client" | jq .name | sed 's@.*/@@' | tr -d \")
    client_secret=$(echo "$iap_oauth_client" | jq .secret | tr -d \")
    gcloud alpha iap web enable --resource-type=backend-services --oauth2-client-id="$client_id" --oauth2-client-secret="$client_secret" --service="${connection_name}-be"
    for i in ${groups//,/ }; do
      gcloud alpha iap web add-iam-policy-binding --resource-type=backend-services --service="${connection_name}-be" --member="group:$i" --role='roles/iap.httpsResourceAccessor'
    done
    for i in ${users//,/ }; do
      gcloud alpha iap web add-iam-policy-binding --resource-type=backend-services --service="${connection_name}-be" --member="user:$i" --role='roles/iap.httpsResourceAccessor'
    done
  fi
}

unpublish_app() {
  check_network
  local connection_name="${1}"
  local frontend_protocol="${2}"
  operation=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" "https://beyondcorp.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/${REGION}/connections/${connection_name}" | jq -r .error.status)
  if [[ ${operation} == "NOT_FOUND" ]]; then
    error && echo "Connection ${connection_name} was not found"
    return 1
  fi
  fr_name="${connection_name}-psc-fr"
  ipaddr=$(gcloud compute forwarding-rules describe "${fr_name}" --region="${REGION}" | grep IPAddress | awk '{print $2}')
  gcloud compute ssh --command="consul kv delete beyondcorp/port_mapping/\`consul kv get beyondcorp/connection_mapping/${connection_name}\`" nat-vm-"${SUBNET_NAME}" --zone "${REGION}"-a
  gcloud compute ssh --command="consul kv delete beyondcorp/port_mapping/\`consul kv get beyondcorp/connection_mapping/${connection_name}\`" nat-vm-"${SUBNET_NAME}"-ha --zone "${REGION}"-a
  gcloud compute forwarding-rules delete "${connection_name}-xlb-fwdrule" --global
  if [[ "$frontend_protocol" == "https" ]]; then
    gcloud compute target-https-proxies delete "${connection_name}-lb" --global
    gcloud compute ssl-certificates delete "${connection_name}-cert" --global
  else
    gcloud compute addresses describe "${connection_name}-xlb-vip" --global &>/dev/null && gcloud compute addresses delete "${connection_name}-xlb-vip" --global
    gcloud compute target-http-proxies delete "${connection_name}-lb" --global
  fi
  gcloud compute url-maps delete "${connection_name}-map"
  gcloud compute backend-services delete "${connection_name}-be" --global
  gcloud compute health-checks delete "${connection_name}-hc" --global
  iap_oauth_brand=$(gcloud alpha iap oauth-brands list --format="value(name)")
  for i in $(gcloud alpha iap oauth-clients list "$iap_oauth_brand" --filter="displayName=${connection_name}" --format=json | jq -r ".[] | .name"); do
    gcloud alpha iap oauth-clients delete "$i"
  done
}

parse_network() {
  case "${OP}" in
  "create")
    verify_name
    while getopts ":r:p:" o; do
      case "${o}" in
      r)
        local region=${OPTARG}
        ;;
      p)
        local project=${OPTARG}
        ;;
      *)
        error && echo "Unrecognized argument: -${OPTARG}"
        exit 1
        ;;
      esac
    done
    verify_no_extraneous_arguments "$@"
    if [[ -z $region ]] || [[ -z $project ]]; then
      error && echo "-r -p must be specified: -r <REGION> -p <PROJECT_ID>"
      exit 1
    fi
    network_create "$NAME" "$region" "$project"
    ;;
  "delete")
    verify_no_name
    network_delete
    ;;
  "list")
    verify_no_name
    network_list
    ;;
  "-h" | "--help")
    usage_network
    ;;
  "")
    error && echo "Missing argument: <OPERATION:create|delete|list>"
    usage_network
    ;;
  *)
    error && echo "Unrecognized argument: ${OP}"
    ;;
  esac
}

parse_connectors() {
  case "${OP}" in
  "create")
    verify_name
    verify_no_extraneous_arguments "${@}"
    connectors_create "${NAME}"
    ;;
  "delete")
    verify_name
    verify_no_extraneous_arguments "${@}"
    connectors_delete "${NAME}"
    ;;
  "list")
    verify_no_name
    connectors_list
    ;;
  "describe")
    verify_name
    verify_no_extraneous_arguments "${@}"
    connectors_describe "${NAME}"
    ;;
  "-h" | "--help")
    usage_connectors
    ;;
  "")
    error && echo "Missing argument: <OPERATION:create|delete|list>"
    usage_connectors
    ;;
  *)
    error && echo "Unrecognized argument: ${OP}"
    ;;
  esac
}

parse_connections() {
  case "${OP}" in
  "create")
    verify_name
    while getopts ":c:h:p:" o; do
      case "${o}" in
      c)
        local connector_names="${OPTARG}"
        ;;
      h)
        local host="${OPTARG}"
        ;;
      p)
        local port="${OPTARG}"
        ;;
      *)
        error && echo "Unrecognized argument: -${OPTARG}"
        exit 1
        ;;
      esac
    done
    verify_no_extraneous_arguments "${@}"
    if [[ -z "${connector_names}" ]] || [[ -z "${host}" ]] || [[ -z "${port}" ]]; then
      error && echo "-c -h -p must be specified: -c <CONNECTOR_NAME,...> -h <APP_HOST> -p <APP_PORT>"
      exit 1
    fi
    connections_create "${NAME}" "${connector_names}" "${host}" "${port}"
    ;;
  "delete")
    verify_name
    verify_no_extraneous_arguments "${@}"
    connections_delete "${NAME}"
    ;;
  "list")
    verify_no_name
    connections_list
    ;;
  "describe")
    verify_name
    verify_no_extraneous_arguments "${@}"
    connections_describe "${NAME}"
    ;;
  "-h" | "--help")
    usage_connections
    ;;
  "")
    error && echo "Missing argument: <OPERATION:create|delete|list>"
    usage_connections
    ;;
  *)
    error && echo "Unrecognized argument: ${OP}"
    ;;
  esac
}

parse_app() {
  case "${OP}" in
  "publish")
    verify_name
    while getopts ":f:b:d:i:eg:u:" o; do
      case "${o}" in
      f)
        if [[ ${OPTARG} != "http" ]] && [[ ${OPTARG} != "https" ]]; then
          error && echo "-f can only be http or https"
          exit 1
        fi
        local frontend_protocol=${OPTARG}
        ;;
      b)
        if [[ ${OPTARG} != "http" ]] && [[ ${OPTARG} != "https" ]]; then
          error && echo "-b can only be http or https"
          exit 1
        fi
        local backend_protocol=${OPTARG}
        ;;
      d)
        local domain=${OPTARG}
        ;;
      i)
        if ! [[ "${OPTARG}" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
          error && echo "-i has invalid IPv4 address format"
          exit 1
        fi
        local ipaddr=${OPTARG}
        ;;
      e)
        local iap=true
        ;;
      g)
        local groups=${OPTARG}
        ;;
      u)
        local users=${OPTARG}
        ;;
      *)
        error && echo "Unrecognized argument: -${OPTARG}"
        exit 1
        ;;
      esac
    done
    verify_no_extraneous_arguments "$@"
    if [[ -z $frontend_protocol ]] || [[ -z $backend_protocol ]]; then
      error && echo "-f -b must be specified: -f <FRONTEND_PROTOCOL:http|https> -b <BACKEND_PROTOCOL:http|https>"
      exit 1
    fi
    if [[ $frontend_protocol == "https" ]] && [[ -z $domain ]]; then
      error && echo "-d must be specified when -f=https: -d <DOMAIN>"
      exit 1
    fi
    if [[ $frontend_protocol == "http" ]] && [[ -n $domain ]]; then
      warn && echo "Domain is ignored because you set -f=http"
    fi
    if [[ $frontend_protocol == "https" ]] && [[ -n $ipaddr ]]; then
      warn && echo "IP is ignored because you set -f=https, it will be inferred from the provided domain instead"
    fi
    if [[ $frontend_protocol == "http" ]] && [[ -z $ipaddr ]]; then
      info && echo "No IP address provided, one will be provisioned for you dynamically"
    fi
    publish_app "$NAME" "$frontend_protocol" "$backend_protocol" "$domain" "$ipaddr" "$iap" "$groups" "$users"
    ;;
  "unpublish")
    verify_name
    while getopts ":f:" o; do
      case "${o}" in
      f)
        if [[ ${OPTARG} != "http" ]] && [[ ${OPTARG} != "https" ]]; then
          error && echo "-f can only be http or https"
          exit 1
        fi
        local frontend_protocol=${OPTARG}
        ;;
      *)
        error && echo "Unrecognized argument: -${OPTARG}"
        exit 1
        ;;
      esac
    done
    verify_no_extraneous_arguments "$@"
    if [[ -z $frontend_protocol ]]; then
      error && echo "-f must be specified: -f <FRONTEND_PROTOCOL:http|https>"
      exit 1
    fi
    unpublish_app "$NAME" "$frontend_protocol"
    ;;
  "-h" | "--help")
    usage_app
    ;;
  "")
    error && echo "Missing argument: <OPERATION:publish|unpublish>"
    usage_app
    ;;
  *)
    error && echo "Unrecognized argument: ${OP}"
    ;;
  esac
}

main() {
  check_dependencies

  OPTIND=4
  case "${RESOURCE}" in
  "network")
    parse_network "$@"
    ;;
  "connectors")
    parse_connectors "$@"
    ;;
  "connections")
    parse_connections "$@"
    ;;
  "app")
    parse_app "$@"
    ;;
  "-h" | "--help")
    usage
    ;;
  "")
    error && echo "Missing argument: <RESOURCE:network|connectors|connections|app>"
    usage
    ;;
  *)
    error && echo "Unrecognized argument: ${RESOURCE}"
    usage
    ;;
  esac
}

# Load the required variables from the settings file if it exists
if [[ -f "$HOME/bce_network_settings" ]]; then
  NETWORK_NAME=$(grep '^network=' "$HOME/bce_network_settings" | cut -f 2 -d=)
  SUBNET_NAME=$(grep '^subnet=' "$HOME/bce_network_settings" | cut -f 2 -d=)
  REGION=$(grep '^region=' "$HOME/bce_network_settings" | cut -f 2 -d=)
  PROJECT_ID=$(grep '^project=' "$HOME/bce_network_settings" | cut -f 2 -d=)
fi

main "$@"
