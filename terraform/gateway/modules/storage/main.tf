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

locals {
  # Map of "${var.prefix}-${key}-mig" format MIG name to corresponding Instance URI list.
  mig-name-instance-uri-list-map = { for u in data.google_compute_region_instance_group.all : u.name => u.instances[*].instance if u.name != null }

  # Map for application key to connector key to connection config.
  # Regex is used inside the template for getting instance-name & zone from instance uri.
  application-account-config-map = {
    for key in keys(var.application_map) : key => {
      for connector in keys(var.application_map[key].connector_key_service_account_map) : connector => {
        config_file = templatefile("${path.module}/../templates/application_config.tmpl", {
          project_id     = var.project_id
          application    = key
          mig_name       = "${var.prefix}-${key}-mig"
          app_endpoint   = var.application_map[key].app_endpoint
          tunnels_per_gw = var.tunnels_per_gw
          instances      = local.mig-name-instance-uri-list-map["${var.prefix}-${key}-mig"]
          interface      = var.tunnel_interface
          port           = var.tunnel_port
        })
      } if contains(keys(local.mig-name-instance-uri-list-map), "${var.prefix}-${key}-mig")
    }
  }

  # Set of application-connector combinations.
  application-connector-set = toset(
    flatten(
      [
        for key in keys(var.application_map) : [
          for account in keys(var.application_map[key].connector_key_service_account_map) : "${key}_${account}"
        ] if contains(keys(local.mig-name-instance-uri-list-map), "${var.prefix}-${key}-mig")
      ]
    )
  )
}

# For fetching project_number
data "google_project" "project" {
  project_id = var.project_id
}

# Fetch data about MIGs.
data "google_compute_region_instance_group" "all" {
  project  = var.project_id
  for_each = var.application_map
  region   = var.application_map[each.key].region
  name     = "${var.prefix}-${each.key}-mig"
}

# Connection config per application inside connections folder inside the connector's storage bucket.
resource "google_storage_bucket_object" "connections_folders" {
  for_each = local.application-connector-set
  bucket   = "${data.google_project.project.number}-connector-${split("_", each.value)[1]}"
  name     = "connections/${split("_", each.value)[0]}"
  content  = local.application-account-config-map[split("_", each.value)[0]][split("_", each.value)[1]].config_file
}