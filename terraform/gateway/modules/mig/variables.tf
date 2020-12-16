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

variable "prefix" {
  description = "Prefix for use in name of components"
}

variable "service_port" {
  description = "Port for the load balancer backend service provided by the MIG"
  type        = number
}

variable "tunnel_port" {
  description = "Port for the IAP TCP tunnel."
  type        = number
}

variable "service_port_name" {
  description = "Name for the service port"
  type        = string
}

variable "image" {
  description = "The Docker image to deploy to GCE instances"
  type        = string
}

variable "target_tag" {
  description = "Tag to use as target_tag in instance template."
  type        = string
}

variable "machine_type" {
  description = "Machine type to create, e.g. n1-standard-1"
  default     = "n1-standard-1"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  default     = "100"
}

variable "disk_type" {
  description = "Boot disk type, can be either pd-ssd, local-ssd, or pd-standard"
  default     = "pd-standard"
}

variable "auto_delete" {
  description = "Whether or not the boot disk should be auto-deleted"
  default     = "true"
}

variable "subnetwork_map" {
  description = "Map from application key to information about the GCP sub-networks."
  type        = map(object({ name : string, subnetwork_self_link : string }))
}

variable "application_map" {
  description = "Map from unique keys for applications to their configurations."
  type = map(object({
    region              = string
    subnetwork_cidr     = string
    mig_instance_count  = number
    additional_metadata = map(string)
  }))
}