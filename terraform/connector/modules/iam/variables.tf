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

variable "connector_map" {
  description = "Map from unique keys for connectors to their metadata."
  type        = map(object({ service_account_name : string, impersonating_account_email : string }))
}

variable "sa_depends_on" {
  type        = any
  default     = null
  description = "Variable to depend_on for creation of eventually consistent service accounts before use in ACLs."
}