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
  # Set of all service accounts in var.application_map.
  service-account-set = toset(flatten([
    for key in keys(var.application_map) : [
      for account in values(var.application_map[key].connector_key_service_account_map) :
      account.service_account_email
    ]
  ]))
}

# Create IAM binding to grant connector SAs compute.viewer role on the project.
resource "google_project_iam_member" "compute_viewer" {
  project  = var.project_id
  for_each = local.service-account-set

  role = "roles/compute.viewer"

  member = format("serviceAccount:%s", each.value)
}

# Create IAM binding to grant connector SAs iap.tunnelResourceAccessor role on the project.
resource "google_project_iam_member" "iap_tcp" {
  project  = var.project_id
  for_each = local.service-account-set

  role = "roles/iap.tunnelResourceAccessor"

  member = format("serviceAccount:%s", each.value)
}