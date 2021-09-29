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

variable "iap_brand_name" {
  description = "Identifier of the brand to which the client is attached to."
  type        = string
}

variable "app_name" {
  description = "The name of the application."
  type        = string
}

variable "app_endpoint" {
  description = "FQDN:PORT | IP:PORT the application."
  type        = string
}

variable "dns_name" {
  description = "The DNS name of the application, for instance `example.com.`"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy instances into"
  type        = string
  default     = "us-central1"
}

variable "subnetwork_cidr" {
  description = "CIDR range of the subnetwork to deploy instances into"
  type        = string
  default     = "10.158.0.0/20"
}

variable "mig_instance_count" {
  description = "The number of instances to place in the managed instance group"
  type        = number
  default     = 1
}

variable "iap_web_app_users" {
  description = "List of user email-ids allowed access by IAP for the application. Ignored if enable_iap is false."
  type        = list(string)
  default     = []
}

variable "image" {
  description = "The Docker image to deploy to GCE instances"
  type        = string
  default     = "gcr.io/cloud-applink-external-release/applink_gw:unstable"
}

variable "connector_info" {
  description = "Map from connector keys to their relevant information. The output of connector module can directly be used for this."
  type        = map(object({ service_account_email : string }))
}

variable "backend_service_timeout" {
  description = "Time in seconds to wait for the application to respond before considering it failed."
  type        = number
  default     = 10
}

variable "backend_service_protocol" {
  description = "The protocol BackendService uses to communicate with backends. Possible values are HTTP, HTTPS."
  type        = string
  default     = "HTTPS"
}

variable "enable_iap" {
  description = "If true creates a internal OAuth 2 client and enables Identity-Aware Proxy (IAP) for the GCP backend service representing the application."
  type        = bool
  default     = true
}
