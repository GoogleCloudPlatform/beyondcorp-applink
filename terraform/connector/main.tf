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
  connector-map = {
    for key in keys(google_service_account.service_accounts) : key =>
    {
      service_account_id : google_service_account.service_accounts[key].account_id
      service_account_name : google_service_account.service_accounts[key].name
      service_account_email : google_service_account.service_accounts[key].email
      additional_metadata : var.connector_map[key].additional_metadata
      impersonating_account_email : var.connector_map[key].impersonating_account_email
    }
  }
}

# Create a service account for each connector.
resource "google_service_account" "service_accounts" {
  project      = var.project_id
  for_each     = var.connector_map
  account_id   = "connector-${each.key}-sa"
  display_name = "Service Account for a BCE Applink connector."
  description  = var.connector_map[each.key].description
}

# Introduce delay as creation of service accounts is eventually consistent.
# 60s based on https://cloud.google.com/iam/docs/creating-managing-service-accounts
resource "null_resource" "delay" {
  for_each = var.connector_map
  provisioner "local-exec" {
    command = "sleep 60"
  }
  triggers = {
    "before" = google_service_account.service_accounts[each.key].id
  }
}

# Setup pubsub to communicate with connectors.
module "pubsub" {
  source        = "./modules/pubsub"
  project_id    = var.project_id
  connector_map = local.connector-map
  sa_depends_on = null_resource.delay[*]
}

# Setup storage for connectors.
module "storage" {
  source               = "./modules/storage"
  project_id           = var.project_id
  connector_map        = local.connector-map
  connector_pubsub_map = module.pubsub.connector_pubsub_map
  sa_depends_on        = null_resource.delay[*]
}

module "iam" {
  source        = "./modules/iam"
  project_id    = var.project_id
  connector_map = local.connector-map
  sa_depends_on = null_resource.delay[*]
}