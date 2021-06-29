/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  description = "The project ID to deploy resource into"
  type        = string
}

variable "image" {
  description = "The Docker image to deploy to GCE instances"
  type        = string
  default     = "gcr.io/cloud-applink-external-release/applink_gw:unstable"
}

variable "healthcheck_type" {
  description = "Specifies the GCLB health check type. Http health check is not implemented yet. (grpc|http|tcp)"
  type        = string
  default     = "grpc"
}

variable "tunnels_per_gw" {
  description = "Number of tunnels to start per gateway instance."
  type        = number
  default     = 1
}

# keys= 1-10 char; RFC 1035 compliant; unique
variable "application_map" {
  description = "Map from unique keys for applications to their configurations."
  type = map(object(
    {
      region = string
      # Ensure CIDRs for different applications do not overlap.
      subnetwork_cidr         = string
      mig_instance_count      = number
      backend_service_timeout = number
      # Application endpoint (FQDN:PORT | IP:PORT)
      app_endpoint = string
      # Map from connector keys to it's service account details.
      connector_key_service_account_map = map(object({ service_account_email : string }))
      protocol                          = string
      # IAP config for the backend service.
      iap_config = object({
        enable               = bool
        oauth2_client_id     = string
        oauth2_client_secret = string
      })
      # String key-value pairs to be made available inside the gateway VMs as part of instance metadata.
      additional_metadata = map(string)
    }
    )
  )
}
