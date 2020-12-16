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

provider "google" {
  project = var.project_id
  version = "~> 3.0"
}

provider "google-beta" {
  project = var.project_id
  version = "~> 3.0"
}

// Note: Only internal org iap clients are supported.
// Other types of clients must be manually created via the GCP console.
resource "google_iap_client" "project_client" {
  display_name = "IAP protected app: ${var.app_name}"
  brand        = var.iap_brand_name
  count        = var.enable_iap ? 1 : 0
}

module "gateway" {
  source     = "../../"
  project_id = var.project_id
  image      = var.image
  application_map = {
    "${var.app_name}" : {
      region                            = var.region
      subnetwork_cidr                   = var.subnetwork_cidr
      mig_instance_count                = var.mig_instance_count
      backend_service_timeout           = var.backend_service_timeout
      app_endpoint                      = var.app_endpoint
      connector_key_service_account_map = var.connector_info
      iap_config = {
        enable               = var.enable_iap
        oauth2_client_id     = var.enable_iap ? google_iap_client.project_client[0].client_id : ""
        oauth2_client_secret = var.enable_iap ? google_iap_client.project_client[0].secret : ""
      }
      additional_metadata = { key1 : "value2", key2 : "value2" }
    },
  }
}

# IAM binding for Identity-Aware Proxy WebBackendService for the application
resource "google_iap_web_backend_service_iam_member" "member" {
  project             = var.project_id
  for_each            = var.enable_iap ? toset(var.iap_web_app_users) : toset([])
  web_backend_service = module.gateway.application_info[var.app_name]["backend_service_name"]
  role                = "roles/iap.httpsResourceAccessor"
  member              = format("user:%s", each.value)
}

# HTTPS Load balancer front-end configurations

# Static external IP address for the external LB
resource "google_compute_global_address" "default" {
  project = var.project_id
  name    = "${var.app_name}-address"
}
# Managed SSL cert for use by LB
resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  name     = "${var.app_name}-ssl-cert"
  managed {
    domains = [var.dns_name]
  }
}
# External LB configuration
resource "google_compute_global_forwarding_rule" "https" {
  project    = var.project_id
  name       = "${var.app_name}-https-forwarding-rule"
  ip_address = google_compute_global_address.default.address
  target     = google_compute_target_https_proxy.default.self_link
  port_range = "443"
}
# Target proxy for use by LB
resource "google_compute_target_https_proxy" "default" {
  project          = var.project_id
  name             = "${var.app_name}-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}
# URL Map for use by LB
resource "google_compute_url_map" "default" {
  provider        = google-beta
  name            = "${var.app_name}-https-lb"
  default_service = module.gateway.application_info[var.app_name]["backend_service"]
}
