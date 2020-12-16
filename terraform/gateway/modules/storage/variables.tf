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

variable "tunnel_port" {
  description = "Port used by connector to connect to gateway instance over IAP TCP."
}

variable "tunnel_interface" {
  description = "Port used by connector to connect to gateway instance over IAP TCP."
}

variable "tunnels_per_gw" {
  description = "Number of tunnels to start per gateway instance."
  type        = number
  default     = 1
}

variable "application_map" {
  description = "Map from unique keys for applications to their configurations."
  type = map(object(
    {
      app_endpoint = string
      region       = string
      # Map from connector keys to it's service account details.
      connector_key_service_account_map = map(object({ service_account_email : string }))
    }
    )
  )
}