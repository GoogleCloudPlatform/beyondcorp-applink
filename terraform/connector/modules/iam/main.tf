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
  sa-impersonating-account-map = { for key in keys(var.connector_map) : key => var.connector_map[key] if var.connector_map[key].impersonating_account_email != "" }
}

# Add serviceAccountUser IAM role for the SAs to the impersonating account.
resource "google_service_account_iam_member" "service-account-user" {
  for_each           = local.sa-impersonating-account-map
  service_account_id = local.sa-impersonating-account-map[each.key].service_account_name
  role               = "roles/iam.serviceAccountUser"
  member             = format("user:%s", local.sa-impersonating-account-map[each.key].impersonating_account_email)
  depends_on         = [var.sa_depends_on]
}

# Add serviceAccountTokenCreator IAM role for the SAs to the impersonating account.
resource "google_service_account_iam_member" "service-account-token-creator" {
  for_each           = local.sa-impersonating-account-map
  service_account_id = local.sa-impersonating-account-map[each.key].service_account_name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = format("user:%s", local.sa-impersonating-account-map[each.key].impersonating_account_email)
  depends_on         = [var.sa_depends_on]
}