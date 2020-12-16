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

# keys: 1-15 char; RFC 1035 compliant; unique; lowercase
# Example:
/*connector_map = {
   c1 : { impersonating_account_email : "conector-admin@example.com", description : "Connector 1 for BCE Applink", additional_metadata : { key1 : "value1", key2 : "value2" } },
   c2 : { impersonating_account_email : "conector-admin@example.com", description : "Connector 2 for BCE Applink", additional_metadata : { key3 : "value3", key4 : "value4" } },
}*/
variable "connector_map" {
  description = "Map from unique keys for connectors to their description and additional metadata."
  type        = map(object({ impersonating_account_email : string, description : string, additional_metadata : map(string) }))
}