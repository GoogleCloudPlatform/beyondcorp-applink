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

variable "network" {
  description = "The name of the GCP network to deploy instances into"
  type        = string
}

variable "request_gw_ports" {
  description = "List of all ports that need access via IAP TCP"
  type        = list(string)
}

variable "prefix" {
  description = "Prefix for use in name of components"
  type        = string
}

variable "service_port" {
  description = "Port for the load balancer backend service provided by the MIG"
  type        = number
}

variable "grpc_hc_port" {
  description = "Port for the load balancer to health check backend service using gRPC provided by the MIG"
  type        = number
}

variable "target_tag" {
  description = "Tag of use as target_tag in firewalls."
  type        = string
}

variable "application_map" {
  description = "Map from unique keys for applications to their configurations."
  type = map(object({
    region          = string
    subnetwork_cidr = string
  }))
}